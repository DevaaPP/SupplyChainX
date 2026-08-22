from fastapi import APIRouter
from app.schemas.ai import AIChatRequest, AIChatResponse
from app.services.ai_service import AIService

router = APIRouter(prefix="/ai", tags=["GenAI Operations Assistant (GenAI Team Module)"])

@router.post("/chat", response_model=AIChatResponse)
def ai_assistant_chat(req: AIChatRequest):
    result = AIService.answer_query(message=req.message, product_id=req.context_product_id)
    return AIChatResponse(**result)
