from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ProductCreate(BaseModel):
    product_id: Optional[str] = None # Auto-generated if omitted (e.g. SCX-00112)
    name: str
    batch_number: str
    category: str = "Food & Agriculture"
    description: Optional[str] = None
    factory_location: str

class ProductResponse(BaseModel):
    id: str
    name: str
    batch_number: str
    category: str
    description: Optional[str] = None
    factory_location: str
    manufacturer_id: str
    manufacturer_name: str
    current_owner_id: str
    current_owner_name: str
    current_role: str
    current_stage: int
    hmac_signature: str
    genesis_hash: str
    latest_block_hash: str
    is_authentic: bool
    is_tampered: bool
    tamper_reason: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class QRDataPayload(BaseModel):
    product_id: str
    name: str
    batch_number: str
    manufacturer: str
    timestamp: str
    hmac_signature: str
    raw_qr_string: str
