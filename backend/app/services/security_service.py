import json
from typing import Dict, Any, Union
from datetime import datetime
from app.core.security import generate_hmac_signature, verify_hmac_signature

class SecurityService:
    @staticmethod
    def _format_time(t: Union[str, datetime]) -> str:
        if isinstance(t, datetime):
            return t.strftime("%Y-%m-%dT%H:%M:%SZ")
        return str(t)

    @staticmethod
    def sign_product(
        product_id: str,
        name: str,
        batch_number: str,
        manufacturer_id: str,
        factory_location: str,
        created_at: Union[str, datetime]
    ) -> str:
        payload = {
            "product_id": product_id,
            "name": name,
            "batch_number": batch_number,
            "manufacturer_id": manufacturer_id,
            "factory_location": factory_location,
            "created_at": SecurityService._format_time(created_at)
        }
        return generate_hmac_signature(payload)

    @staticmethod
    def verify_product_hmac(
        product_id: str,
        name: str,
        batch_number: str,
        manufacturer_id: str,
        factory_location: str,
        created_at: Union[str, datetime],
        signature: str
    ) -> bool:
        payload = {
            "product_id": product_id,
            "name": name,
            "batch_number": batch_number,
            "manufacturer_id": manufacturer_id,
            "factory_location": factory_location,
            "created_at": SecurityService._format_time(created_at)
        }
        return verify_hmac_signature(payload, signature)

    @staticmethod
    def create_qr_payload(
        product_id: str,
        name: str,
        batch_number: str,
        manufacturer_name: str,
        created_at: Union[str, datetime],
        signature: str
    ) -> str:
        qr_dict = {
            "scx_version": "1.0",
            "product_id": product_id,
            "name": name,
            "batch": batch_number,
            "mfg": manufacturer_name,
            "issued": SecurityService._format_time(created_at),
            "sig": signature
        }
        return json.dumps(qr_dict)
