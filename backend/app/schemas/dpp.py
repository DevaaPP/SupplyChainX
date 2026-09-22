from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class RawMaterialOrigin(BaseModel):
    material_name: str
    country_of_origin: str
    supplier_name: str
    sustainability_cert: str

class DigitalProductPassportResponse(BaseModel):
    product_id: str
    product_name: str
    batch_number: str
    category: str
    manufacturer: str
    manufacturing_date: str
    origin_factory: str
    current_status: str
    custodian: str
    is_authentic: bool
    hmac_signature_seal: str
    blockchain_tx_hash: str
    carbon_footprint_kg_co2e: float
    recyclability_pct: float
    raw_materials: List[RawMaterialOrigin] = []
    passport_qr_url: str

class CustomerPortalProductResponse(BaseModel):
    product_id: str
    name: str
    batch_number: str
    brand_owner: str
    authenticity_badge: str # VERIFIED_GENUINE, UNVERIFIED
    current_location: str
    status_summary: str
    estimated_arrival: str
    journey_checkpoints_count: int
    hmac_seal: str
