from fastapi import APIRouter
from app.schemas.settlement import EscrowLockRequest, EscrowReleaseRequest, EscrowSettlementResponse
from app.services.payment_service import PaymentService

router = APIRouter(prefix="/settlement", tags=["Smart Contract Escrow & Settlement Payments Module"])

@router.post("/escrow", response_model=EscrowSettlementResponse)
def lock_escrow_payment(req: EscrowLockRequest):
    """Lock payment funds in Smart Contract Escrow upon shipment genesis dispatch."""
    return PaymentService.lock_escrow_funds(req)

@router.post("/release", response_model=EscrowSettlementResponse)
def release_escrow_settlement(req: EscrowReleaseRequest):
    """Release escrow payment upon custody delivery, applying SLA delay penalty deductions if applicable."""
    return PaymentService.release_escrow_settlement(req)
