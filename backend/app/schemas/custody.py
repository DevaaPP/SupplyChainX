from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime

class CustodyTransferRequest(BaseModel):
    product_id: str
    actor_id: Optional[str] = None
    actor_name: Optional[str] = None
    recipient_id: Optional[str] = None
    recipient_name: str
    recipient_role: str # distributor, warehouse, retailer, customer
    location: str
    action: str # e.g. "Transferred to Transit Hub", "Stored in Bay 4", "Dispatched to Retail", "Purchased at POS"
    notes: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

class CustodyBlockResponse(BaseModel):
    id: str
    product_id: str
    block_index: int
    stage_name: str
    role: str
    actor_id: str
    actor_name: str
    location: str
    action: str
    notes: Optional[str] = None
    previous_hash: str
    block_hash: str
    tx_hash: str
    timestamp: datetime

    class Config:
        from_attributes = True

class ChainVerificationResponse(BaseModel):
    product_id: str
    product_name: str
    batch_number: str
    category: str
    factory_location: str
    manufacturer_name: str
    current_owner: str
    current_stage: int
    total_stages: int = 5
    
    # Cryptographic verdict
    is_authentic: bool
    is_tampered: bool
    tamper_reason: Optional[str] = None
    hmac_verified: bool
    chain_integrity_verified: bool
    genesis_hash: str
    latest_block_hash: str
    
    # Chain timeline
    blocks: List[CustodyBlockResponse]
    verified_at: datetime
