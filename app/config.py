"""
SupplyChainX — Centralized configuration.

All paths, feature lists, and constants in one place so nothing is
hardcoded across modules.

Security:
    Secrets are loaded from a .env file via python-dotenv.
    The .env file is git-ignored and never committed.
"""

import os
import logging
from pathlib import Path
from dotenv import load_dotenv


# ── Load environment variables from .env ─────────────────────────────
# This MUST happen before any os.environ.get() calls below.
load_dotenv(override=False)

logger = logging.getLogger(__name__)

# ── Project root (one level above app/) ──────────────────────────────
BASE_DIR = Path(__file__).resolve().parent.parent

# ── Model artifacts ──────────────────────────────────────────────────
MODEL_PATH = BASE_DIR / "models" / "delivery_time_model.pkl"
BASELINES_PATH = BASE_DIR / "models" / "delay_baselines.pkl"

# ── Training data (needed for SHAP background samples) ───────────────
PROCESSED_DATA_PATH = BASE_DIR / "data" / "processed" / "delivery_features_v2.csv"

# ── Feature definitions ──────────────────────────────────────────────
NUMERIC_FEATURES = [
    "Agent_Age", "Agent_Rating", "Distance", "Preparation_Time",
    "Order_Hour", "Peak_Hour", "Is_Weekend", "Is_Quick_Commerce",
]

CATEGORICAL_FEATURES = [
    "Weather", "Traffic", "Vehicle", "Area", "Category", "Time_of_Day",
]

ALL_FEATURES = NUMERIC_FEATURES + CATEGORICAL_FEATURES

# ── Valid values for categorical features ────────────────────────────
VALID_WEATHER = ["Cloudy", "Fog", "Sandstorms", "Stormy", "Sunny", "Windy"]
VALID_TRAFFIC = ["High", "Jam", "Low", "Medium"]
VALID_VEHICLE = ["motorcycle", "scooter", "van"]
VALID_AREA = ["Metropolitian", "Other", "Semi-Urban", "Urban"]
VALID_CATEGORY = [
    "Apparel", "Books", "Clothing", "Cosmetics", "Electronics",
    "Grocery", "Home", "Jewelry", "Kitchen", "Outdoors",
    "Pet Supplies", "Shoes", "Skincare", "Snacks", "Sports", "Toys",
]
VALID_TIME_OF_DAY = ["Afternoon", "Evening", "Morning", "Night"]

# ── Google Gemini settings ───────────────────────────────────────────
# Loaded securely from .env — never hardcode API keys in source code.
GOOGLE_API_KEY = (
    os.environ.get("GOOGLE_API_KEY") or os.environ.get("GEMINI_API_KEY") or ""
).strip().strip('"').strip("'")
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-3.6-flash").strip().strip('"').strip("'")

# ── HuggingFace settings (local embeddings only) ─────────────────────
HF_EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"

if not GOOGLE_API_KEY:
    logger.warning(
        "GOOGLE_API_KEY is not set. "
        "The /ask endpoint will fail. "
        "Add your key to the .env file in the project root."
    )

# ── Application settings (from .env) ────────────────────────────────
ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.environ.get("ALLOWED_ORIGINS", "*").split(",")
    if origin.strip()
]

LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()
HOST = os.environ.get("HOST", "0.0.0.0")
PORT = int(os.environ.get("PORT", "8000"))


