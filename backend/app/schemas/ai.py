from pydantic import BaseModel, Field
from typing import Optional, List, Any, Dict
from app.schemas.ml import OrderInput, PredictionResponse

class AIChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000, description="User query or instruction")
    context_product_id: Optional[str] = Field(None, description="Optional product/consignment ID for context")
    user_role: Optional[str] = Field("customer", description="Role of the requesting user (manufacturer, distributor, warehouse, retailer, customer)")
    order: Optional[OrderInput] = Field(None, description="Optional delivery order features")

class ToolCallExecution(BaseModel):
    tool_name: str
    arguments: Dict[str, Any]
    result_summary: str

class AIChatResponse(BaseModel):
    reply: str
    referenced_products: Optional[List[str]] = []
    suggested_actions: Optional[List[str]] = []
    prediction: Optional[Dict[str, Any]] = None
    grounded_in_ledger: Optional[bool] = False
    user_role: Optional[str] = "customer"
    executed_tools: Optional[List[ToolCallExecution]] = []

class AskRequest(BaseModel):
    order: OrderInput
    question: str = Field(..., min_length=1, max_length=1000, description="Customer question")

class AskResponse(BaseModel):
    answer: str
    prediction: PredictionResponse


