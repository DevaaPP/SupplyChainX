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
            "sig": signature,
            "verify_url": f"https://supplychainx.com/verify/{product_id}"
        }
        return json.dumps(qr_dict)

    @staticmethod
    def generate_verification_url(product_id: str, host: Union[str, None] = None) -> str:
        """
        Packaging QR Generation
        Creates verification URL: https://supplychainx.com/verify/{product_id}
        """
        if host and host not in ["localhost", "127.0.0.1"]:
            return f"http://{host}:3000/verify/{product_id}"
        return f"https://supplychainx.com/verify/{product_id}"

    @staticmethod
    def generate_qr_png_bytes(data: str) -> bytes:
        """
        Packaging QR Generation
        Converts verification URL into visible square QR image bytes.
        The same QR stays on physical product while its blockchain history changes.
        """
        import io
        import qrcode

        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_M,
            box_size=10,
            border=4,
        )
        qr.add_data(data)
        qr.make(fit=True)
        img = qr.make_image(fill_color="#0F172A", back_color="white")
        
        buf = io.BytesIO()
        img.save(buf, format="PNG")
        return buf.getvalue()

    @staticmethod
    def generate_qr_base64(data: str) -> str:
        """Generates a data:image/png;base64,... string for inline rendering."""
        import base64
        png_bytes = SecurityService.generate_qr_png_bytes(data)
        b64 = base64.b64encode(png_bytes).decode("utf-8")
        return f"data:image/png;base64,{b64}"

