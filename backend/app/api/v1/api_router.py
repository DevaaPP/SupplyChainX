from fastapi import APIRouter

from app.api.v1.auth_routes import router as auth_router
from app.api.v1.product_routes import router as product_router
from app.api.v1.custody_routes import router as custody_router
from app.api.v1.audit_routes import router as audit_router
from app.api.v1.ml_routes import router as ml_router
from app.api.v1.ai_routes import router as ai_router
from app.api.v1.blockchain_routes import router as blockchain_router
from app.api.v1.analytics_routes import router as analytics_router
from app.api.v1.iot_routes import router as iot_router
from app.api.v1.event_routes import router as event_router
from app.api.v1.cv_routes import router as cv_router
from app.api.v1.route_routes import router as route_router
from app.api.v1.dpp_routes import router as dpp_router
from app.api.v1.portal_routes import router as portal_router
from app.api.v1.anomaly_routes import router as anomaly_router
from app.api.v1.sustainability_routes import router as sustainability_router
from app.api.v1.report_routes import router as report_router
from app.api.v1.simulation_routes import router as simulation_router

from app.api.v1.settlement_routes import router as settlement_router
from app.api.v1.anti_cloning_routes import router as anti_cloning_router
from app.api.v1.shelf_life_routes import router as shelf_life_router
from app.api.v1.notification_routes import router as notification_router

api_router = APIRouter()

# 🛡️ Core Cybersecurity & Custody Routers
api_router.include_router(auth_router)
api_router.include_router(product_router)
api_router.include_router(custody_router)
api_router.include_router(audit_router)

# 🔌 Plug-in Modules & Telemetry Routers
api_router.include_router(ml_router)
api_router.include_router(ai_router)
api_router.include_router(blockchain_router)
api_router.include_router(analytics_router)
api_router.include_router(iot_router)
api_router.include_router(event_router)

# 🚀 Enterprise Industry 4.0 Advanced Routers
api_router.include_router(cv_router)
api_router.include_router(route_router)
api_router.include_router(dpp_router)
api_router.include_router(portal_router)
api_router.include_router(anomaly_router)
api_router.include_router(sustainability_router)
api_router.include_router(report_router)
api_router.include_router(simulation_router)

# 💎 High-Impact Production Real-World Routers
api_router.include_router(settlement_router)
api_router.include_router(anti_cloning_router)
api_router.include_router(shelf_life_router)
api_router.include_router(notification_router)



