from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.schemas.ai import AIChatRequest, AIChatResponse, AskRequest, AskResponse
from app.schemas.ml import PredictionResponse, ReasonItem
from app.services.ai_service import AIService

router = APIRouter(prefix="/ai", tags=["GenAI Operations Assistant (GenAI Team Module)"])

@router.post("/chat", response_model=AIChatResponse)
def ai_assistant_chat(req: AIChatRequest, db: Session = Depends(get_db)):
    """
    RAG-powered conversational operations assistant grounded in live blockchain
    ledger provenance, ML transit predictions, and standard operating policies.
    """
    order_data = req.order.model_dump() if req.order else None
    result = AIService.answer_query(
        message=req.message,
        product_id=req.context_product_id,
        order_dict=order_data,
        db=db
    )
    return AIChatResponse(**result)

@router.post("/ask", response_model=AskResponse)
def ask_assistant(req: AskRequest, db: Session = Depends(get_db)):
    """
    Full grounded assistant pipeline combining ML delivery prediction, SHAP reasons,
    RAG vector search, and Gemini generation.
    """
    order_dict = req.order.model_dump()
    result = AIService.answer_query(
        message=req.question,
        order_dict=order_dict,
        db=db
    )
    pred_data = result.get("prediction") or {}
    reasons = pred_data.get("reasons", [])

    return AskResponse(
        answer=result["reply"],
        prediction=PredictionResponse(
            expected_delivery_time_minutes=pred_data.get("expected_delivery_time_minutes", 0.0),
            baseline_time_minutes=pred_data.get("baseline_time_minutes", 0.0),
            is_delayed=pred_data.get("is_delayed", False),
            delay_minutes=pred_data.get("delay_minutes", 0.0),
            reasons=[ReasonItem(**r) for r in reasons]
        )
    )

