from fastapi import APIRouter

from app.api.v1.auth_routes import router as auth_router
from app.api.v1.product_routes import router as product_router
from app.api.v1.custody_routes import router as custody_router
from app.api.v1.audit_routes import router as audit_router
from app.api.v1.ml_routes import router as ml_router
from app.api.v1.ai_routes import router as ai_router
from app.api.v1.blockchain_routes import router as blockchain_router
from app.api.v1.analytics_routes import router as analytics_router

api_router = APIRouter()

# 🛡️ Core Cybersecurity & Custody Routers
api_router.include_router(auth_router)
api_router.include_router(product_router)
api_router.include_router(custody_router)
api_router.include_router(audit_router)

# 🔌 Plug-in Modules for Other Teams
api_router.include_router(ml_router)
api_router.include_router(ai_router)
api_router.include_router(blockchain_router)
api_router.include_router(analytics_router)
