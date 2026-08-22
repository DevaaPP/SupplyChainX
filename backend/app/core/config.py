import os
from pathlib import Path
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict
from dotenv import load_dotenv

# Search for .env in current dir or project root
_BASE_DIR = Path(__file__).resolve().parent.parent.parent # backend/
_ROOT_DIR = _BASE_DIR.parent # SupplychainX/
_env_path = _ROOT_DIR / ".env" if (_ROOT_DIR / ".env").exists() else _BASE_DIR / ".env"
load_dotenv(dotenv_path=_env_path, override=False)

class Settings(BaseSettings):
    model_config = SettingsConfigDict(case_sensitive=True, extra="ignore")

    PROJECT_NAME: str = "SupplyChainX"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Paths
    BASE_DIR: Path = _BASE_DIR
    ROOT_DIR: Path = _ROOT_DIR
    MODEL_PATH: Path = _ROOT_DIR / "models" / "delivery_time_model.pkl"
    BASELINES_PATH: Path = _ROOT_DIR / "models" / "delay_baselines.pkl"
    PROCESSED_DATA_PATH: Path = _ROOT_DIR / "data" / "processed" / "delivery_features_v2.csv"

    # Cryptographic Secrets
    SECRET_KEY: str = os.getenv("SECRET_KEY", "scx_super_secret_jwt_key_928374928174912")
    HMAC_SECRET: str = os.getenv("HMAC_SECRET", "scx_hmac_sha256_qr_barcode_secret_key_847192")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", f"sqlite:///{_BASE_DIR / 'supplychainx.db'}")
    
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

    # Blockchain node endpoint
    WEB3_RPC_URL: str = os.getenv("WEB3_RPC_URL", "http://127.0.0.1:8545")
    CONTRACT_ADDRESS: str = os.getenv("CONTRACT_ADDRESS", "0x0000000000000000000000000000000000000000")

    # LLM API (Google Gemini & OpenAI)
    GOOGLE_API_KEY: str = (os.getenv("GOOGLE_API_KEY") or os.getenv("GEMINI_API_KEY") or "").strip().strip('"').strip("'")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-3.6-flash").strip().strip('"').strip("'")
    HF_EMBEDDING_MODEL: str = "sentence-transformers/all-MiniLM-L6-v2"
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")

    # ML Feature lists & validation
    NUMERIC_FEATURES: List[str] = [
        "Agent_Age", "Agent_Rating", "Distance", "Preparation_Time",
        "Order_Hour", "Peak_Hour", "Is_Weekend", "Is_Quick_Commerce",
    ]
    CATEGORICAL_FEATURES: List[str] = [
        "Weather", "Traffic", "Vehicle", "Area", "Category", "Time_of_Day",
    ]
    VALID_WEATHER: List[str] = ["Cloudy", "Fog", "Sandstorms", "Stormy", "Sunny", "Windy"]
    VALID_TRAFFIC: List[str] = ["High", "Jam", "Low", "Medium"]
    VALID_VEHICLE: List[str] = ["motorcycle", "scooter", "van"]
    VALID_AREA: List[str] = ["Metropolitian", "Other", "Semi-Urban", "Urban"]
    VALID_CATEGORY: List[str] = [
        "Apparel", "Books", "Clothing", "Cosmetics", "Electronics",
        "Grocery", "Home", "Jewelry", "Kitchen", "Outdoors",
        "Pet Supplies", "Shoes", "Skincare", "Snacks", "Sports", "Toys",
    ]
    VALID_TIME_OF_DAY: List[str] = ["Afternoon", "Evening", "Morning", "Night"]

settings = Settings()

