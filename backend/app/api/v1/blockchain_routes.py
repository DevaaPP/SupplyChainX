from fastapi import APIRouter
from app.services.blockchain_service import BlockchainService

router = APIRouter(prefix="/blockchain", tags=["Blockchain & Web3 (Blockchain Team Module)"])

@router.get("/status")
def get_blockchain_status():
    return BlockchainService.get_blockchain_status()

@router.get("/tx/{tx_hash}")
def get_transaction(tx_hash: str):
    return BlockchainService.get_transaction_details(tx_hash)
