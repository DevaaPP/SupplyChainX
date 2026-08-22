from pydantic import BaseModel, Field
from typing import Optional, List
from app.schemas.ml import OrderInput, PredictionResponse

class AIChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000, description="User query or instruction")
    context_product_id: Optional[str] = Field(None, description="Optional product/consignment ID for context")
    order: Optional[OrderInput] = Field(None, description="Optional delivery order features")

class AIChatResponse(BaseModel):
    reply: str
    referenced_products: Optional[List[str]] = []
    suggested_actions: Optional[List[str]] = []
    prediction: Optional[PredictionResponse] = None
    grounded_in_ledger: Optional[bool] = False

class AskRequest(BaseModel):
    order: OrderInput
    question: str = Field(..., min_length=1, max_length=1000, description="Customer question")

class AskResponse(BaseModel):
    answer: str
    prediction: PredictionResponse

