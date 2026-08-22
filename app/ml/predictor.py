"""
SupplyChainX — Delivery time prediction + delay detection.

Ported from notebooks/03_Model_Training_1.ipynb (Steps 9–13).
Loads the saved scikit-learn pipeline and baseline artifacts,
exposes predict_delivery() as the single entry point.
"""

import joblib
import pandas as pd
from app.config import (
    MODEL_PATH,
    BASELINES_PATH,
    NUMERIC_FEATURES,
    CATEGORICAL_FEATURES,
)

# ── Load artifacts once at import time ───────────────────────────────
_pipeline = joblib.load(MODEL_PATH)
_baseline_artifact = joblib.load(BASELINES_PATH)

_cat_area_baseline = _baseline_artifact["cat_area_baseline"]
_cat_baseline = _baseline_artifact["cat_baseline"]
_overall_baseline = _baseline_artifact["overall_baseline"]
_DELAY_THRESHOLD = _baseline_artifact["delay_threshold_minutes"]


# ── Baseline lookup (from notebook 03, Step 10) ──────────────────────
def _get_baseline(category: str, area: str) -> float:
    """Return the normal-conditions median delivery time for this Category+Area."""
    if (category, area) in _cat_area_baseline:
        return _cat_area_baseline[(category, area)]
    if category in _cat_baseline:
        return _cat_baseline[category]
    return _overall_baseline


# ── Delay detection (from notebook 03, Step 11) ──────────────────────
def _compute_delay(predicted_time: float, category: str, area: str) -> dict:
    baseline = _get_baseline(category, area)
    delay_minutes = max(0.0, predicted_time - baseline)
    is_delayed = delay_minutes > _DELAY_THRESHOLD
    return {
        "baseline_time": round(float(baseline), 1),
        "delay_minutes": round(float(delay_minutes), 1),
        "is_delayed": bool(is_delayed),
    }


# ── Public API ───────────────────────────────────────────────────────
def predict_delivery(order: dict) -> dict:
    """
    Predict delivery time and detect delay for a single order.

    Parameters
    ----------
    order : dict
        Raw feature columns matching the training schema
        (Agent_Age, Agent_Rating, Distance, …, Time_of_Day).

    Returns
    -------
    dict with keys:
        expected_delivery_time_minutes, baseline_time_minutes,
        is_delayed, delay_minutes
    """
    input_df = pd.DataFrame([order])
    predicted_time = float(_pipeline.predict(input_df)[0])
    delay_info = _compute_delay(predicted_time, order["Category"], order["Area"])

    return {
        "expected_delivery_time_minutes": round(predicted_time, 1),
        "baseline_time_minutes": delay_info["baseline_time"],
        "is_delayed": delay_info["is_delayed"],
        "delay_minutes": delay_info["delay_minutes"],
    }


def get_pipeline():
    """Return the loaded sklearn pipeline (for SHAP explainer access)."""
    return _pipeline
