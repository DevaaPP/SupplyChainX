from typing import List
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.models.product import Product
from app.models.custody_block import CustodyBlock
from app.schemas.custody import (
    CustodyTransferRequest,
    CustodyBlockResponse,
    ChainVerificationResponse
)
from typing import Optional
from app.core.rbac import get_current_user, get_optional_current_user
from app.services.custody_service import CustodyService

router = APIRouter(prefix="/custody", tags=["Cryptographic Custody & Provenance"])

@router.post("/transfer", response_model=CustodyBlockResponse)
def transfer_custody(
    req: CustodyTransferRequest,
    user: Optional[User] = Depends(get_optional_current_user),
    db: Session = Depends(get_db)
):
    try:
        prod = db.query(Product).filter(Product.id == req.product_id).first()
        if not prod:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Product {req.product_id} not found on ledger")

        actor_id = req.actor_id or (user.id if user else prod.current_owner_id) or "usr-operator"
        actor_name = req.actor_name or (user.display_name if user else prod.current_owner_name) or "Authorized Operator"

        block = CustodyService.append_custody_transfer(
            db=db,
            product_id=req.product_id,
            actor_id=actor_id,
            actor_name=actor_name,
            recipient_id=req.recipient_id or f"usr-{req.recipient_role[:3]}",
            recipient_name=req.recipient_name,
            recipient_role=req.recipient_role.lower(),
            location=req.location,
            action=req.action,
            notes=req.notes
        )

        # Synchronize to Blockchain EVM State
        try:
            from app.services.blockchain_service import BlockchainService, DEFAULT_ACCOUNTS
            to_acc = DEFAULT_ACCOUNTS.get(req.recipient_role.lower(), DEFAULT_ACCOUNTS["retailer"])
            BlockchainService.transfer_product(
                product_id=req.product_id,
                to_address=to_acc,
                new_location=req.location,
                action=req.action
            )
        except Exception:
            pass

        return CustodyBlockResponse.model_validate(block)
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.get("/verify/{product_id}", response_model=ChainVerificationResponse)
def verify_provenance(product_id: str, db: Session = Depends(get_db)):
    result = CustodyService.verify_product_chain(db=db, product_id=product_id)
    if not result.get("found"):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Consignment {product_id} not registered on cryptographic ledger."
        )

    product = result["product"]
    blocks = result["blocks"]

    return ChainVerificationResponse(
        product_id=product.id,
        product_name=product.name,
        batch_number=product.batch_number,
        category=product.category,
        factory_location=product.factory_location,
        manufacturer_name=product.manufacturer_name,
        current_owner=product.current_owner_name,
        current_stage=product.current_stage,
        total_stages=5,
        is_authentic=result["is_authentic"],
        is_tampered=result["is_tampered"],
        tamper_reason=result.get("tamper_reason"),
        hmac_verified=result["hmac_verified"],
        chain_integrity_verified=result["chain_integrity_verified"],
        genesis_hash=product.genesis_hash,
        latest_block_hash=product.latest_block_hash,
        blocks=[CustodyBlockResponse.model_validate(b) for b in blocks],
        verified_at=datetime.now(timezone.utc)
    )

@router.get("/chain/{product_id}", response_model=List[CustodyBlockResponse])
def get_custody_chain(product_id: str, db: Session = Depends(get_db)):
    blocks = db.query(CustodyBlock)\
        .filter(CustodyBlock.product_id == product_id)\
        .order_by(CustodyBlock.block_index.asc())\
        .all()
    if not blocks:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"No ledger blocks for {product_id}")
    return [CustodyBlockResponse.model_validate(b) for b in blocks]
