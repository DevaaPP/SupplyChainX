from fastapi import APIRouter, HTTPException, Path, Body, Query
from typing import Optional, Dict, Any
from app.services.blockchain_service import BlockchainService
from app.schemas.blockchain import (
    RegisterProductOnChainRequest,
    TransferProductOnChainRequest,
    UpdateLocationOnChainRequest,
    VerifyProductOnChainRequest
)

router = APIRouter(prefix="/api/products", tags=["Blockchain Guide Direct API (Section 15)"])

@router.post("")
def register_product_guide(req: RegisterProductOnChainRequest):
    """POST /api/products — registerProduct() on blockchain."""
    try:
        return BlockchainService.register_product(
            product_id=req.product_id,
            product_hash=req.product_hash,
            initial_location=req.initial_location,
            name=req.name,
            batch_number=req.batch_number
        )
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/showcase")
def provision_showcase_product_guide(
    template: Optional[str] = Body("tea", embed=True, description="Template key: tea, pharma, electronics, agriculture"),
    custom_id: Optional[str] = Body(None, embed=True, description="Optional custom product ID")
):
    """POST /api/products/showcase — Dynamically provisions authentic showcase consignment."""
    try:
        return BlockchainService.provision_showcase_product(
            template_key=template,
            custom_id=custom_id
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/{product_id}/transfer")
def transfer_product_guide(
    product_id: str = Path(..., description="Product ID"),
    to_address: str = Body(..., embed=True, description="Recipient Ethereum address"),
    location: str = Body("Highway Transit Corridor", embed=True, description="New location"),
    action: str = Body("Ownership Transferred", embed=True, description="Action description")
):
    """POST /api/products/:id/transfer — transferProduct() on blockchain."""
    try:
        return BlockchainService.transfer_product(
            product_id=product_id,
            to_address=to_address,
            new_location=location,
            action=action
        )
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.put("/{product_id}/location")
def update_location_guide(
    product_id: str = Path(..., description="Product ID"),
    location: str = Body(..., embed=True, description="New physical location"),
    status: str = Body("In Transit", embed=True, description="New status string")
):
    """PUT /api/products/:id/location — updateLocation() on blockchain."""
    try:
        return BlockchainService.update_location(
            product_id=product_id,
            new_location=location,
            new_status=status
        )
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/{product_id}")
def get_product_guide(product_id: str = Path(..., description="Product ID")):
    """GET /api/products/:id — getProduct() on blockchain."""
    try:
        return BlockchainService.get_product(product_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/{product_id}/history")
def get_product_history_guide(product_id: str = Path(..., description="Product ID")):
    """GET /api/products/:id/history — getProductHistory() on blockchain."""
    try:
        return BlockchainService.get_product_history(product_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/{product_id}/verify")
def verify_product_guide(
    product_id: str = Path(..., description="Product ID"),
    claim_hash: Optional[str] = Query(None, description="Optional bytes32 hash to verify")
):
    """GET /api/products/:id/verify — verifyProduct() on blockchain."""
    return BlockchainService.verify_product(
        product_id=product_id,
        claim_hash=claim_hash
    )
