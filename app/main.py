"""
SupplyChainX — FastAPI backend.

Two endpoints:
    POST /predict  →  Delivery time prediction + delay detection + SHAP reasons
    POST /ask      →  AI assistant (RAG-powered natural-language answers)

Both endpoints accept the same order schema.
The /ask endpoint additionally takes a question string.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Literal, Optional
import pandas as pd
import logging

from app.config import (
    VALID_WEATHER, VALID_TRAFFIC, VALID_VEHICLE,
    VALID_AREA, VALID_CATEGORY, VALID_TIME_OF_DAY,
    ALLOWED_ORIGINS, LOG_LEVEL,
)

# ── Logging ──────────────────────────────────────────────────────────
logging.basicConfig(level=getattr(logging, LOG_LEVEL, logging.INFO))
logger = logging.getLogger(__name__)

# ── FastAPI app ──────────────────────────────────────────────────────
app = FastAPI(
    title="SupplyChainX API",
    description=(
        "ML-powered delivery time prediction and AI supply chain assistant. "
        "Part of the SupplyChainX platform."
    ),
    version="1.0.0",
)

# CORS — origins loaded from .env (ALLOWED_ORIGINS).
# If wildcard "*" is used, allow_credentials must be False per the CORS specification.
is_wildcard = ALLOWED_ORIGINS == ["*"] or "*" in ALLOWED_ORIGINS
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=not is_wildcard,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request / Response schemas ───────────────────────────────────────
class OrderInput(BaseModel):
    """Input features for delivery time prediction matching training distributions."""
    Agent_Age: int = Field(..., ge=20, le=39, description="Delivery agent's age (trained on 20-39)")
    Agent_Rating: float = Field(..., ge=1.0, le=5.0, description="Agent performance rating")
    Distance: float = Field(..., ge=1.0, le=25.0, description="Distance in km (haversine, trained on 1.5-21 km)")
    Preparation_Time: float = Field(..., ge=5.0, le=15.0, description="Prep time in minutes (trained on 5-15 min)")
    Order_Hour: int = Field(..., ge=0, le=23, description="Hour of order (0-23)")
    Peak_Hour: int = Field(..., ge=0, le=1, description="1 if peak hour, 0 otherwise")
    Is_Weekend: int = Field(..., ge=0, le=1, description="1 if weekend, 0 otherwise")
    Is_Quick_Commerce: int = Field(..., ge=0, le=1, description="1 if Grocery, 0 otherwise")
    Weather: str = Field(..., description="Weather condition")
    Traffic: str = Field(..., description="Traffic condition")
    Vehicle: str = Field(..., description="Vehicle type")
    Area: str = Field(..., description="Delivery area type")
    Category: str = Field(..., description="Product category")
    Time_of_Day: str = Field(..., description="Time of day bucket")


class ReasonItem(BaseModel):
    feature: str
    value: Optional[str]
    impact_minutes: float


class PredictionResponse(BaseModel):
    expected_delivery_time_minutes: float
    baseline_time_minutes: float
    is_delayed: bool
    delay_minutes: float
    reasons: list[ReasonItem] = []


class AskRequest(BaseModel):
    order: OrderInput
    question: str = Field(..., min_length=1, max_length=500, description="Customer question")


class AskResponse(BaseModel):
    answer: str
    prediction: PredictionResponse


# ── Validation helper ────────────────────────────────────────────────
def _validate_categoricals(order: OrderInput) -> None:
    errors = []
    if order.Weather not in VALID_WEATHER:
        errors.append(f"Weather must be one of {VALID_WEATHER}")
    if order.Traffic not in VALID_TRAFFIC:
        errors.append(f"Traffic must be one of {VALID_TRAFFIC}")
    if order.Vehicle not in VALID_VEHICLE:
        errors.append(f"Vehicle must be one of {VALID_VEHICLE}")
    if order.Area not in VALID_AREA:
        errors.append(f"Area must be one of {VALID_AREA}")
    if order.Category not in VALID_CATEGORY:
        errors.append(f"Category must be one of {VALID_CATEGORY}")
    if order.Time_of_Day not in VALID_TIME_OF_DAY:
        errors.append(f"Time_of_Day must be one of {VALID_TIME_OF_DAY}")
    if errors:
        raise HTTPException(status_code=422, detail=errors)


from fastapi.responses import FileResponse
from pathlib import Path

# ── Endpoints ────────────────────────────────────────────────────────
@app.get("/")
def root():
    """Health check."""
    return {
        "service": "SupplyChainX API",
        "status": "running",
        "endpoints": ["/predict", "/ask", "/docs", "/ui"],
    }


@app.get("/ui", response_class=FileResponse)
@app.get("/dashboard", response_class=FileResponse)
def serve_ui():
    """Serve the interactive SupplyChainX Dashboard UI."""
    html_path = Path(__file__).resolve().parent.parent / "ui_prototype.html"
    if html_path.exists():
        return FileResponse(html_path)
    raise HTTPException(status_code=404, detail="UI prototype file not found")


@app.post("/predict", response_model=PredictionResponse)
def predict(order: OrderInput):
    """
    Predict delivery time, detect delay, and explain reasons.

    Returns the predicted delivery time in minutes, whether the order
    is delayed relative to the category baseline, the delay amount,
    and the top contributing factors (via SHAP).
    """
    _validate_categoricals(order)
    order_dict = order.model_dump()

    # Lazy import to avoid loading SHAP at startup if only /ask is used
    from app.ml.predictor import predict_delivery
    from app.ml.explainer import explain_prediction

    prediction = predict_delivery(order_dict)

    # Add SHAP reasons if delayed
    if prediction["is_delayed"]:
        input_df = pd.DataFrame([order_dict])
        reasons = explain_prediction(input_df)
    else:
        reasons = []

    return PredictionResponse(
        expected_delivery_time_minutes=prediction["expected_delivery_time_minutes"],
        baseline_time_minutes=prediction["baseline_time_minutes"],
        is_delayed=prediction["is_delayed"],
        delay_minutes=prediction["delay_minutes"],
        reasons=[ReasonItem(**r) for r in reasons],
    )


@app.post("/ask", response_model=AskResponse)
def ask(request: AskRequest):
    """
    Ask the AI supply chain assistant a question about an order.

    Combines ML prediction, SHAP explanation, RAG retrieval, and
    LLM generation to produce a grounded natural-language answer.
    """
    _validate_categoricals(request.order)
    order_dict = request.order.model_dump()

    from app.genai.assistant import ask_assistant

    result = ask_assistant(order_dict, request.question)

    prediction_data = result["prediction"]
    reasons = prediction_data.pop("reasons", [])

    return AskResponse(
        answer=result["answer"],
        prediction=PredictionResponse(
            **prediction_data,
            reasons=[ReasonItem(**r) for r in reasons],
        ),
    )
