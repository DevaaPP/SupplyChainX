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

from app.models.inventory import Inventory
from app.models.supplier import Supplier
from app.models.iot_telemetry import IoTTelemetry, SensorAlert


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

        # Seed Suppliers if empty
        if db.query(Supplier).count() == 0:
            sample_suppliers = [
                Supplier(id="sup-01", name="Assam Organic Estates", category="Beverages & Tea", total_orders=1240, on_time_delivery_rate=94.2, avg_delay_minutes=18.0, defect_rate=1.8, lead_time_days=4.2, reliability_score=91.4),
                Supplier(id="sup-02", name="Guwahati Microelectronics", category="IoT Sensors & Electronics", total_orders=850, on_time_delivery_rate=91.5, avg_delay_minutes=22.4, defect_rate=2.1, lead_time_days=5.1, reliability_score=88.7),
                Supplier(id="sup-03", name="Brahmaputra Cold-Chain Bio", category="Pharmaceuticals", total_orders=620, on_time_delivery_rate=98.1, avg_delay_minutes=8.5, defect_rate=0.4, lead_time_days=3.0, reliability_score=96.8),
            ]
            db.add_all(sample_suppliers)
            db.commit()

        # Seed Inventory if empty
        if db.query(Inventory).count() == 0:
            sample_inventory = [
                Inventory(id="inv-01", product_id="SCX-TEA-01", product_name="Assam Organic Single-Estate Tea 250g", sku="SKU-TEA-250", stock_level=240, reorder_point=100, status="Healthy"),
                Inventory(id="inv-02", product_id="SCX-MED-02", product_name="Cold-Chain Rapid Bio-Insulin 100IU", sku="SKU-MED-100", stock_level=42, reorder_point=80, status="Low"),
                Inventory(id="inv-03", product_id="SCX-IOT-03", product_name="Industrial IoT Telemetry Sensor Gateway", sku="SKU-IOT-500", stock_level=12, reorder_point=50, status="Critical"),
            ]
            db.add_all(sample_inventory)
            db.commit()

        # Seed Products if empty
        if db.query(Product).count() == 0:
            try:
                from app.services.blockchain_service import BlockchainService
                BlockchainService.provision_showcase_product(template_key="tea")
                BlockchainService.provision_showcase_product(template_key="pharma")
                BlockchainService.provision_showcase_product(template_key="electronics")
            except Exception:
                pass

    finally:
        db.close()


from app.services.event_consumers import register_all_event_consumers

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    Base.metadata.create_all(bind=engine)
    seed_initial_data()
    register_all_event_consumers()
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

