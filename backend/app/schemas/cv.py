from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class ImageCVVerifyRequest(BaseModel):
    product_id: str = Field("SCX-00112", description="Product or consignment ID")
    image_base64_hash: Optional[str] = Field("hash_pkg_7f8a91c", description="Base64 or SHA-256 hash of packaging image")
    nfc_uid_tag: Optional[str] = Field("NFC-TAG-9941A", description="NFC UID tag identifier")

class ImageCVVerifyResponse(BaseModel):
    product_id: str
    is_authentic: bool
    confidence_score_pct: float
    visual_match_status: str # VERIFIED_MATCH, SUSPICIOUS_ANOMALY, UNKNOWN
    label_consistency_score: float
    nfc_tag_verified: bool
    detected_anomalies: List[str] = []
    verdict_summary: str
