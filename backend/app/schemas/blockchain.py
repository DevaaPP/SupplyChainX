from pydantic import BaseModel, Field
from typing import Optional, List, Any

class SetRoleRequest(BaseModel):
    account: str = Field(..., description="Target wallet address (e.g. 0x...)")
    role: int = Field(..., ge=0, le=5, description="Role ID: 0=None, 1=Manufacturer, 2=Distributor, 3=Warehouse, 4=Retailer, 5=Customer")

class RegisterProductOnChainRequest(BaseModel):
    product_id: str = Field(..., description="Unique product ID (e.g. SCX-001)")
    product_hash: Optional[str] = Field(None, description="Bytes32 hex string. If omitted, computed deterministically")
    name: Optional[str] = Field(None, description="Product Name (e.g. Organic Basmati Rice 5kg)")
    batch_number: Optional[str] = Field(None, description="Batch number (e.g. BAT-2026-X102)")
    initial_location: str = Field("Guwahati Factory", description="Factory / Genesis location")

class TransferProductOnChainRequest(BaseModel):
    product_id: str = Field(..., description="Product ID to transfer")
    to_address: str = Field(..., description="Recipient Ethereum address")
    new_location: str = Field(..., description="New location of the consignment")
    action: Optional[str] = Field("Ownership Transferred", description="Action label")

class UpdateLocationOnChainRequest(BaseModel):
    product_id: str = Field(..., description="Product ID")
    new_location: str = Field(..., description="Updated physical location")
    new_status: str = Field(..., description="Updated status string (e.g. 'In Transit', 'Customs Cleared')")

class VerifyProductOnChainRequest(BaseModel):
    product_id: str = Field(..., description="Product ID (e.g. SCX-001)")
    claim_hash: Optional[str] = Field(None, description="Optional bytes32 hash to verify")
    qr_data: Optional[str] = Field(None, description="Optional raw scanned QR string")

class HistoryRecordResponse(BaseModel):
    from_address: str
    to_address: str
    location: str
    action: str
    timestamp: str

class ProductOnChainResponse(BaseModel):
    product_id: str
    product_hash: str
    manufacturer: str
    current_owner: str
    current_location: str
    status: str
    created_at: str
    exists: bool
    qr_url: str
    qr_hash: str

class VerifyProductResponse(BaseModel):
    product_id: str
    is_valid: bool
    exists: bool
    current_owner: str
    status: str
    current_location: str
    message: str

class BlockchainStatusResponse(BaseModel):
    network: str
    node_status: str
    consensus: str
    total_blocks_sealed: int
    smart_contract_address: str
    deployer_address: str
    evm_compatibility: str
    is_live_rpc: bool
