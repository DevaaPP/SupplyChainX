import hmac
import hashlib
import json
import base64
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional, Union
import jwt
import bcrypt
from cryptography.fernet import Fernet
from app.core.config import settings

# ─── Password Hashing using direct bcrypt ────────────────────────────────────
def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        password_bytes = plain_password.encode('utf-8')[:72]
        hashed_bytes = hashed_password.encode('utf-8')
        return bcrypt.checkpw(password_bytes, hashed_bytes)
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    password_bytes = password.encode('utf-8')[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password_bytes, salt).decode('utf-8')


# ─── JWT Authentication ──────────────────────────────────────────────────────
def create_access_token(
    subject: Union[str, Any],
    role: str,
    expires_delta: Optional[timedelta] = None
) -> str:
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode = {
        "exp": expire,
        "sub": str(subject),
        "role": role,
        "iat": datetime.now(timezone.utc),
    }
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str) -> Optional[Dict[str, Any]]:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except (jwt.PyJWTError, Exception):
        return None


# ─── Cryptographic HMAC-SHA256 QR Barcode Signing ────────────────────────────
def generate_hmac_signature(payload_dict: Dict[str, Any]) -> str:
    """
    Computes deterministic HMAC-SHA256 digital signature over serialized product metadata.
    Any tampering with serial number, batch, manufacturer, or origin breaks this signature.
    """
    canonical_data = json.dumps(payload_dict, sort_keys=True, separators=(',', ':')).encode('utf-8')
    signature = hmac.new(
        settings.HMAC_SECRET.encode('utf-8'),
        canonical_data,
        hashlib.sha256
    ).hexdigest()
    return signature

def verify_hmac_signature(payload_dict: Dict[str, Any], expected_signature: str) -> bool:
    """
    Verifies that the provided HMAC-SHA256 signature matches the canonical metadata.
    Uses hmac.compare_digest to prevent timing side-channel attacks.
    """
    computed = generate_hmac_signature(payload_dict)
    return hmac.compare_digest(computed, expected_signature)


# ─── SHA-256 Block Hash Generator (Chain of Custody) ─────────────────────────
def calculate_block_hash(
    index: int,
    previous_hash: str,
    timestamp: str,
    action: str,
    actor_id: str,
    actor_role: str,
    location: str,
    product_id: str
) -> str:
    """
    Computes SHA-256 cryptographic hash linking a custody block to its predecessor.
    """
    block_string = f"{index}:{previous_hash}:{timestamp}:{action}:{actor_id}:{actor_role}:{location}:{product_id}"
    return hashlib.sha256(block_string.encode('utf-8')).hexdigest()


# ─── AES-256 Vault Encryption ────────────────────────────────────────────────
def _get_fernet_cipher() -> Fernet:
    key = hashlib.sha256(settings.SECRET_KEY.encode('utf-8')).digest()
    fernet_key = base64.urlsafe_b64encode(key)
    return Fernet(fernet_key)

def encrypt_sensitive_data(plain_text: str) -> str:
    cipher = _get_fernet_cipher()
    return cipher.encrypt(plain_text.encode('utf-8')).decode('utf-8')

def decrypt_sensitive_data(encrypted_text: str) -> str:
    cipher = _get_fernet_cipher()
    return cipher.decrypt(encrypted_text.encode('utf-8')).decode('utf-8')
