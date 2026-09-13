from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from datetime import datetime, timezone
import hashlib

from app.core.config import settings
from app.core.security import get_password_hash
from app.db.database import engine, Base, SessionLocal
from app.models.user import User
from app.models.product import Product
from app.models.custody_block import CustodyBlock
from app.models.audit_log import AuditLog
from app.api.v1.api_router import api_router
from app.services.security_service import SecurityService
from app.services.custody_service import CustodyService

def seed_initial_data():
    db = SessionLocal()
    try:
        # 1. Seed demo users if empty or ensure admin exists
        admin_user = db.query(User).filter(User.email == "admin@supply.com").first()
        if not admin_user:
            admin_user = User(
                id="usr-admin",
                email="admin@supply.com",
                hashed_password=get_password_hash("demo1234"),
                display_name="Enterprise Security Auditor",
                role="admin",
                organization="Global Ledger Governance & Audit",
                is_2fa_enabled=True
            )
            db.add(admin_user)
            db.commit()

        if db.query(User).count() <= 1:
            demo_users = [
                User(id="usr-mfg", email="manufacturer@supply.com", hashed_password=get_password_hash("demo1234"), display_name="Guwahati Food Corp", role="manufacturer", organization="Guwahati Manufacturing Div 1", is_2fa_enabled=True),
                User(id="usr-dist", email="distributor@supply.com", hashed_password=get_password_hash("demo1234"), display_name="Siliguri Logistics Hub", role="distributor", organization="Eastern Transit Fleet", is_2fa_enabled=False),
                User(id="usr-wh", email="warehouse@supply.com", hashed_password=get_password_hash("demo1234"), display_name="Kolkata Central Warehouse", role="warehouse", organization="Eastern Regional Distribution", is_2fa_enabled=True),
                User(id="usr-ret", email="retailer@supply.com", hashed_password=get_password_hash("demo1234"), display_name="Metro Retail Store #4", role="retailer", organization="Metro Supermarkets Ltd", is_2fa_enabled=False),
                User(id="usr-cust", email="customer@supply.com", hashed_password=get_password_hash("demo1234"), display_name="Vikram Mehta", role="customer", organization=None, is_2fa_enabled=False),
            ]
            db.add_all(demo_users)
            db.commit()

    finally:
        db.close()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    Base.metadata.create_all(bind=engine)
    seed_initial_data()
    yield
    # Shutdown

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Operational Supply Chain & Product Traceability Platform Backend",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API v1 router
app.include_router(api_router, prefix=settings.API_V1_STR)

# Mount Blockchain Guide direct routes (/api/products matching Section 15 of guide)
from app.api.products_guide_routes import router as products_guide_router
app.include_router(products_guide_router)

# Top-level alias endpoints for ML prediction & GenAI assistant
from app.api.v1.ml_routes import predict_order_delivery
from app.api.v1.ai_routes import ask_assistant

app.add_api_route("/predict", predict_order_delivery, methods=["POST"], tags=["Machine Learning (ML Team Module)"])
app.add_api_route("/ask", ask_assistant, methods=["POST"], tags=["GenAI Operations Assistant (GenAI Team Module)"])

@app.get("/")
def root():
    return {
        "status": "online",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "docs_url": "/docs",
        "api_v1": settings.API_V1_STR,
        "endpoints": [
            f"{settings.API_V1_STR}/auth/login",
            f"{settings.API_V1_STR}/products",
            f"{settings.API_V1_STR}/custody/transfer",
            f"{settings.API_V1_STR}/custody/verify/{{product_id}}",
            f"{settings.API_V1_STR}/ml/predict-delay",
            f"{settings.API_V1_STR}/ml/predict",
            f"{settings.API_V1_STR}/ai/chat",
            f"{settings.API_V1_STR}/ai/ask",
            "/predict",
            "/ask"
        ]
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()}

