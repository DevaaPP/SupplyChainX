from pydantic import BaseModel
from typing import Optional, List

class AIChatRequest(BaseModel):
    message: str
    context_product_id: Optional[str] = None

class AIChatResponse(BaseModel):
    reply: str
    referenced_products: Optional[List[str]] = None
    suggested_actions: Optional[List[str]] = None
