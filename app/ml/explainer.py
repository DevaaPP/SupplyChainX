"""
SupplyChainX — SHAP-based delay reason explanations.

Ported from notebooks/03_Model_Training_1.ipynb (Step 12).
Uses per-category background samples so SHAP attributions align
with the same baseline that delay_minutes is measured against.
"""

import shap
import pandas as pd
import numpy as np
from app.config import (
    PROCESSED_DATA_PATH,
    NUMERIC_FEATURES,
    CATEGORICAL_FEATURES,
)
from app.ml.predictor import get_pipeline

# ── Load training data for SHAP background samples ──────────────────
_pipeline = get_pipeline()
_rf_model = _pipeline.named_steps["model"]
_preprocessor = _pipeline.named_steps["preprocess"]
_encoded_feature_names = _preprocessor.get_feature_names_out()

_df = pd.read_csv(PROCESSED_DATA_PATH)
_normal_conditions = _df[(_df["Weather"] == "Sunny") & (_df["Traffic"] == "Low")]

# ── Cache for per-category SHAP explainers ───────────────────────────
_category_explainers: dict = {}


def _base_feature_name(name: str) -> str:
    """Map an encoded column name back to its original feature name."""
    if name.startswith("cat__"):
        rest = name.split("__", 1)[1]
        for col in CATEGORICAL_FEATURES:
            if rest.startswith(col + "_"):
                return col
        return rest
    return name.replace("remainder__", "")


def _get_category_explainer(category: str):
    """Build (and cache) a SHAP TreeExplainer for the given category."""
    if category in _category_explainers:
        return _category_explainers[category]

    bg_rows = _normal_conditions[_normal_conditions["Category"] == category]
    if len(bg_rows) < 10:
        bg_rows = _normal_conditions

    bg_sample = bg_rows[NUMERIC_FEATURES + CATEGORICAL_FEATURES].copy()
    bg_sample["Is_Weekend"] = bg_sample["Is_Weekend"].astype(int)
    bg_sample["Is_Quick_Commerce"] = bg_sample["Is_Quick_Commerce"].astype(int)
    bg_sample = bg_sample.sample(min(50, len(bg_sample)), random_state=42)

    bg_encoded = _preprocessor.transform(bg_sample)
    if hasattr(bg_encoded, "toarray"):
        bg_encoded = bg_encoded.toarray()

    explainer = shap.TreeExplainer(
        _rf_model, data=bg_encoded, feature_perturbation="interventional"
    )
    _category_explainers[category] = explainer
    return explainer


def explain_prediction(input_row_df: pd.DataFrame, top_n: int = 3) -> list[dict]:
    """
    Return the top contributing factors for a single prediction.

    Parameters
    ----------
    input_row_df : pd.DataFrame
        Single-row dataframe with the raw feature columns.
    top_n : int
        Maximum number of reasons to return.

    Returns
    -------
    list of dicts, each with keys: feature, value, impact_minutes
    """
    category = input_row_df.iloc[0]["Category"]
    explainer = _get_category_explainer(category)

    encoded = _preprocessor.transform(input_row_df)
    if hasattr(encoded, "toarray"):
        encoded = encoded.toarray()
    shap_values = explainer.shap_values(encoded)[0]

    # Group one-hot columns back to original features
    contributions: dict[str, float] = {}
    for name, val in zip(_encoded_feature_names, shap_values):
        base = _base_feature_name(name)
        contributions[base] = contributions.get(base, 0.0) + val

    ranked = sorted(contributions.items(), key=lambda x: x[1], reverse=True)
    reasons = []
    for feature, impact in ranked[:top_n]:
        if impact > 0.5:
            reasons.append({
                "feature": feature,
                "value": (
                    str(input_row_df.iloc[0][feature])
                    if feature in input_row_df.columns
                    else None
                ),
                "impact_minutes": round(float(impact), 1),
            })
    return reasons
