from fastapi import APIRouter, HTTPException, Query, Body, Path
from typing import Optional, Dict, Any, List

from app.services.blockchain_service import BlockchainService
from app.schemas.blockchain import (
    SetRoleRequest,
    RegisterProductOnChainRequest,
    TransferProductOnChainRequest,
    UpdateLocationOnChainRequest,
    VerifyProductOnChainRequest,
    BlockchainStatusResponse
)

router = APIRouter(prefix="/blockchain", tags=["Blockchain & Smart Contract (SupplyChain.sol)"])

@router.get("/status", response_model=BlockchainStatusResponse)
def get_blockchain_status():
    """Get network connection status, contract address, and total blocks sealed."""
    return BlockchainService.get_blockchain_status()

@router.get("/abi")
def get_contract_abi():
    """Get compiled Solidity ABI for SupplyChain.sol."""
    return BlockchainService.get_abi()

@router.post("/set-role")
def set_role(req: SetRoleRequest):
    """
    Assign role to address: 0=None, 1=Manufacturer, 2=Distributor, 3=Warehouse, 4=Retailer, 5=Customer.
    Only the initial Manufacturer can assign roles.
    """
    try:
        return BlockchainService.set_role(account=req.account, role=req.role)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/register-product")
def register_product(req: RegisterProductOnChainRequest):
    """
    registerProduct(string productId, bytes32 productHash, string initialLocation)
    Manufacturer registers a genuine consignment on-chain with deterministic hash and QR URL.
    """
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

@router.post("/transfer-product")
def transfer_product(req: TransferProductOnChainRequest):
    """
    transferProduct(string productId, address to, string newLocation, string action)
    Current owner transfers custody to the next authorized participant along the chain.
    """
    try:
        return BlockchainService.transfer_product(
            product_id=req.product_id,
            to_address=req.to_address,
            new_location=req.new_location,
            action=req.action or "Ownership Transferred"
        )
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.put("/update-location")
def update_location(req: UpdateLocationOnChainRequest):
    """
    updateLocation(string productId, string newLocation, string newStatus)
    Current owner updates transit checkpoint location or status.
    """
    try:
        return BlockchainService.update_location(
            product_id=req.product_id,
            new_location=req.new_location,
            new_status=req.new_status
        )
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/product/{product_id}")
def get_product(product_id: str = Path(..., description="Product ID (e.g. SCX-001)")):
    """getProduct(string productId) — read on-chain product record."""
    try:
        return BlockchainService.get_product(product_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/history/{product_id}")
def get_product_history(product_id: str = Path(..., description="Product ID")):
    """getProductHistory(string productId) — read full immutable audit trail."""
    try:
        return BlockchainService.get_product_history(product_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.post("/verify")
def verify_product(req: VerifyProductOnChainRequest):
    """
    verifyProduct(string productId, bytes32 claimHash)
    Customer verifies product authenticity by comparing QR code / claim hash with stored on-chain hash.
    """
    return BlockchainService.verify_product(
        product_id=req.product_id,
        claim_hash=req.claim_hash,
        qr_data=req.qr_data
    )

@router.get("/tx/{tx_hash}")
def get_transaction(tx_hash: str):
    """Inspect EVM transaction confirmation and gas usage."""
    return BlockchainService.get_transaction_details(tx_hash)
