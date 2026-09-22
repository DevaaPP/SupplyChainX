from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class EscrowLockRequest(BaseModel):
    product_id: str = Field("SCX-00112", description="Shipment or product ID")
    escrow_amount_inr: float = Field(25000.0, ge=100.0, description="Escrow payment amount in INR")
    carrier_wallet: str = Field("0x70997970C51812dc3A010C7d01b50e0d17dc79C8", description="Carrier Web3 wallet address")
    max_sla_transit_hours: float = Field(12.0, ge=1.0, description="SLA transit time limit in hours")

class EscrowReleaseRequest(BaseModel):
    product_id: str = Field("SCX-00112", description="Shipment or product ID")
    actual_transit_hours: float = Field(14.5, ge=0.0, description="Actual transit time taken in hours")
    is_tampered: bool = Field(False, description="Whether shipment was tampered")

class EscrowSettlementResponse(BaseModel):
    escrow_id: str
    product_id: str
    original_amount_inr: float
    sla_penalty_deduction_inr: float
    final_payout_amount_inr: float
    carrier_wallet: str
    status: str # LOCKED, RELEASED_FULL, RELEASED_WITH_PENALTY, FORFEITED
    blockchain_tx_hash: str
    summary_narrative: str
