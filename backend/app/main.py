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
        # 1. Seed demo users if empty
        if db.query(User).count() == 0:
            demo_users = [
                User(id="usr-mfg", email="manufacturer@supply.com", hashed_password=get_password_hash("demo1234"), display_name="Guwahati Food Corp", role="manufacturer", organization="Guwahati Manufacturing Div 1", is_2fa_enabled=True),
                User(id="usr-dist", email="distributor@supply.com", hashed_password=get_password_hash("demo1234"), display_name="Siliguri Logistics Hub", role="distributor", organization="Eastern Transit Fleet", is_2fa_enabled=False),
                User(id="usr-wh", email="warehouse@supply.com", hashed_password=get_password_hash("demo1234"), display_name="Kolkata Central Warehouse", role="warehouse", organization="Eastern Regional Distribution", is_2fa_enabled=True),
                User(id="usr-ret", email="retailer@supply.com", hashed_password=get_password_hash("demo1234"), display_name="Metro Retail Store #4", role="retailer", organization="Metro Supermarkets Ltd", is_2fa_enabled=False),
                User(id="usr-cust", email="customer@supply.com", hashed_password=get_password_hash("demo1234"), display_name="Vikram Mehta", role="customer", organization=None, is_2fa_enabled=False),
            ]
            db.add_all(demo_users)
            db.commit()

        # 2. Seed initial demo consignments if empty
        if db.query(Product).count() == 0:
            now = datetime.now(timezone.utc)
            now_iso = now.isoformat()
            
            # Product 1: SCX-00112 (Organic Basmati Rice 5kg) — At Retailer (Stage 4)
            p1_sig = SecurityService.sign_product("SCX-00112", "Organic Basmati Rice 5kg", "BAT-2026-X102", "usr-mfg", "Guwahati Unit 1", now)
            p1 = Product(
                id="SCX-00112",
                name="Organic Basmati Rice 5kg",
                batch_number="BAT-2026-X102",
                category="Food & Agriculture",
                description="Premium organic crop harvested from Assam valley.",
                factory_location="Guwahati Unit 1",
                manufacturer_id="usr-mfg",
                manufacturer_name="Guwahati Food Corp",
                current_owner_id="usr-ret",
                current_owner_name="Metro Retail Store #4",
                current_role="retailer",
                current_stage=4,
                hmac_signature=p1_sig,
                genesis_hash="pending",
                latest_block_hash="pending",
                is_authentic=True,
                is_tampered=False,
                created_at=now,
                updated_at=now
            )
            db.add(p1)
            db.commit()
            db.refresh(p1)

            # Genesis Block
            CustodyService.create_genesis_block(db, p1, "usr-mfg", "Guwahati Food Corp", "Guwahati Unit 1", "Batch created & signed HMAC QR sealed")
            # Step 2: Distributor
            CustodyService.append_custody_transfer(db, p1.id, "usr-mfg", "Guwahati Food Corp", "usr-dist", "Siliguri Logistics Hub", "distributor", "Highway NH-27 Corridor", "Carrier Picked Up Consignment", "GPS Telemetry Waypoint Logged")
            # Step 3: Warehouse
            CustodyService.append_custody_transfer(db, p1.id, "usr-dist", "Siliguri Logistics Hub", "usr-wh", "Kolkata Central Warehouse", "warehouse", "Kolkata Hub Bay 4", "Inbound Inspection & Storage", "Quality check passed, ML delay risk nominal")
            # Step 4: Retailer
            CustodyService.append_custody_transfer(db, p1.id, "usr-wh", "Kolkata Central Warehouse", "usr-ret", "Metro Retail Store #4", "retailer", "Metro Store Shelf A-12", "Delivered & Stocked for Retail", "Verified cryptographic lineage")

            # Product 2: SCX-00098 (Darjeeling Tea 250g) — In Transit (Stage 2)
            p2_sig = SecurityService.sign_product("SCX-00098", "Darjeeling First Flush Tea 250g", "BAT-2026-T88", "usr-mfg", "Darjeeling Estate", now)
            p2 = Product(
                id="SCX-00098",
                name="Darjeeling First Flush Tea 250g",
                batch_number="BAT-2026-T88",
                category="Beverages",
                description="Organic premium single-estate tea.",
                factory_location="Darjeeling Estate",
                manufacturer_id="usr-mfg",
                manufacturer_name="Guwahati Food Corp",
                current_owner_id="usr-dist",
                current_owner_name="Siliguri Logistics Hub",
                current_role="distributor",
                current_stage=2,
                hmac_signature=p2_sig,
                genesis_hash="pending",
                latest_block_hash="pending",
                is_authentic=True,
                is_tampered=False,
                created_at=now,
                updated_at=now
            )
            db.add(p2)
            db.commit()
            db.refresh(p2)
            CustodyService.create_genesis_block(db, p2, "usr-mfg", "Guwahati Food Corp", "Darjeeling Estate")
            CustodyService.append_custody_transfer(db, p2.id, "usr-mfg", "Guwahati Food Corp", "usr-dist", "Siliguri Logistics Hub", "distributor", "Transit En Route", "Dispatched to Regional Distributor")

            # Product 3: SCX-00134 (Cold Pressed Mustard Oil 1L) — Manufactured (Stage 1)
            p3_sig = SecurityService.sign_product("SCX-00134", "Cold Pressed Mustard Oil 1L", "BAT-2026-O44", "usr-mfg", "Guwahati Unit 2", now)
            p3 = Product(
                id="SCX-00134",
                name="Cold Pressed Mustard Oil 1L",
                batch_number="BAT-2026-O44",
                category="Food & Agriculture",
                description="Cold pressed virgin organic mustard oil.",
                factory_location="Guwahati Unit 2",
                manufacturer_id="usr-mfg",
                manufacturer_name="Guwahati Food Corp",
                current_owner_id="usr-mfg",
                current_owner_name="Guwahati Food Corp",
                current_role="manufacturer",
                current_stage=1,
                hmac_signature=p3_sig,
                genesis_hash="pending",
                latest_block_hash="pending",
                is_authentic=True,
                is_tampered=False,
                created_at=now,
                updated_at=now
            )
            db.add(p3)
            db.commit()
            db.refresh(p3)
            CustodyService.create_genesis_block(db, p3, "usr-mfg", "Guwahati Food Corp", "Guwahati Unit 2")

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

@app.get("/")
def root():
    return {
        "status": "online",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "docs_url": "/docs",
        "api_v1": settings.API_V1_STR
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()}
