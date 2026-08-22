import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(case_sensitive=True)

    PROJECT_NAME: str = "SupplyChainX"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Cryptographic Secrets
    SECRET_KEY: str = os.getenv("SECRET_KEY", "scx_super_secret_jwt_key_928374928174912")
    HMAC_SECRET: str = os.getenv("HMAC_SECRET", "scx_hmac_sha256_qr_barcode_secret_key_847192")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./supplychainx.db")
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:8000",
        "http://localhost:50000",
        "http://127.0.0.1",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",
        "*",
    ]

    # Blockchain node endpoint (for Blockchain Team integration)
    WEB3_RPC_URL: str = os.getenv("WEB3_RPC_URL", "http://127.0.0.1:8545")
    CONTRACT_ADDRESS: str = os.getenv("CONTRACT_ADDRESS", "0x0000000000000000000000000000000000000000")

    # LLM API (for GenAI Team integration)
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")

settings = Settings()
