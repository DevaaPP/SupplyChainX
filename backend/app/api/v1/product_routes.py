import random
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Body, Query, Response, Request
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.models.product import Product
from app.models.custody_block import CustodyBlock
from app.schemas.product import ProductCreate, ProductResponse, QRDataPayload
from app.core.rbac import get_current_user, require_roles, UserRole
from app.services.security_service import SecurityService
from app.services.custody_service import CustodyService

router = APIRouter(prefix="/products", tags=["Product Registry & HMAC Security"])

def _populate_product_journey(product: Product, db: Session) -> ProductResponse:
    blocks = db.query(CustodyBlock).filter(CustodyBlock.product_id == product.id).order_by(CustodyBlock.block_index.asc()).all()
    p_res = ProductResponse.model_validate(product)
    journey_list = []
    for b in blocks:
        journey_list.append({
            "id": b.id,
            "actor": b.actor_name,
            "actor_name": b.actor_name,
            "role": b.role.capitalize(),
            "action": b.action,
            "location": b.location,
            "timestamp": b.timestamp.isoformat() if b.timestamp else (product.created_at.isoformat() if product.created_at else datetime.now(timezone.utc).isoformat()),
            "blockchainHash": b.block_hash,
            "block_hash": b.block_hash,
            "tx_hash": b.tx_hash,
            "verified": True,
            "notes": b.notes
        })
    p_res.blocks = journey_list
    p_res.journey = journey_list
    return p_res

@router.get("", response_model=List[ProductResponse])
def list_products(
    category: Optional[str] = None,
    current_role: Optional[str] = None,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    query = db.query(Product)
    if category:
        query = query.filter(Product.category == category)
    if current_role:
        query = query.filter(Product.current_role == current_role.lower())
    products = query.order_by(Product.created_at.desc()).limit(limit).all()
    return [_populate_product_journey(p, db) for p in products]

@router.get("/{product_id}", response_model=ProductResponse)
def get_product(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Product {product_id} not found")
    return _populate_product_journey(product, db)

@router.post("/register", response_model=ProductResponse)
def register_product(
    prod_in: ProductCreate,
    user: User = Depends(require_roles([UserRole.MANUFACTURER, UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    # Generate serial if not provided
    product_id = prod_in.product_id or f"SCX-0{random.randint(1000, 9999)}"
    
    # Check if ID already exists
    existing = db.query(Product).filter(Product.id == product_id).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Serial ID {product_id} is already registered on ledger")

    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()

    # Generate Cryptographic HMAC-SHA256 digital signature
    hmac_sig = SecurityService.sign_product(
        product_id=product_id,
        name=prod_in.name,
        batch_number=prod_in.batch_number,
        manufacturer_id=user.id,
        factory_location=prod_in.factory_location,
        created_at=now
    )

    # Instantiate Product record
    product = Product(
        id=product_id,
        name=prod_in.name,
        batch_number=prod_in.batch_number,
        category=prod_in.category,
        description=prod_in.description,
        factory_location=prod_in.factory_location,
        manufacturer_id=user.id,
        manufacturer_name=user.display_name,
        current_owner_id=user.id,
        current_owner_name=user.display_name,
        current_role="manufacturer",
        current_stage=1,
        hmac_signature=hmac_sig,
        genesis_hash="pending",
        latest_block_hash="pending",
        is_authentic=True,
        is_tampered=False,
        created_at=now,
        updated_at=now
    )
    db.add(product)
    db.commit()
    db.refresh(product)

    # Commit Genesis Block #0 on Chain of Custody
    CustodyService.create_genesis_block(
        db=db,
        product=product,
        manufacturer_id=user.id,
        manufacturer_name=user.display_name,
        location=prod_in.factory_location
    )

    # Register on blockchain
    try:
        from app.services.blockchain_service import BlockchainService
        BlockchainService.register_product(
            product_id=product.id,
            product_hash=hmac_sig,
            initial_location=prod_in.factory_location,
            name=product.name,
            batch_number=product.batch_number
        )
    except Exception:
        pass

    return _populate_product_journey(product, db)

@router.post("/showcase", response_model=ProductResponse)
def provision_showcase_product(
    payload: Optional[Dict[str, Any]] = Body(None),
    template: Optional[str] = Query("tea"),
    db: Session = Depends(get_db)
):
    """Provisions a showcase consignment with full blockchain & DB provenance."""
    from app.services.blockchain_service import BlockchainService
    key = (payload.get("template") if payload and isinstance(payload, dict) and "template" in payload else template) or "tea"
    res = BlockchainService.provision_showcase_product(template_key=key)
    prod = db.query(Product).filter(Product.id == res["product_id"]).first()
    if not prod:
        raise HTTPException(status_code=500, detail="Failed to provision showcase product")
    return _populate_product_journey(prod, db)

@router.get("/{product_id}/qr", response_model=QRDataPayload)
def get_product_qr(
    product_id: str,
    request: Request,
    db: Session = Depends(get_db)
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    host = request.headers.get("host", "").split(":")[0] if request else None
    verify_url = SecurityService.generate_verification_url(product.id, host)
    raw_qr = SecurityService.create_qr_payload(
        product_id=product.id,
        name=product.name,
        batch_number=product.batch_number,
        manufacturer_name=product.manufacturer_name,
        created_at=product.created_at,
        signature=product.hmac_signature
    )
    qr_b64 = SecurityService.generate_qr_base64(verify_url)

    return QRDataPayload(
        product_id=product.id,
        name=product.name,
        batch_number=product.batch_number,
        manufacturer=product.manufacturer_name,
        timestamp=product.created_at.isoformat(),
        hmac_signature=product.hmac_signature,
        raw_qr_string=raw_qr,
        verification_url=verify_url,
        qr_base64=qr_b64
    )

@router.get("/{product_id}/qr/image")
def get_product_qr_image(
    product_id: str,
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Physical Packaging QR Generation
    Generates verification URL and direct PNG image for physical product sticker.
    The same QR stays on the physical product while its blockchain history changes.
    """
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    host = request.headers.get("host", "").split(":")[0] if request else None
    verify_url = SecurityService.generate_verification_url(product.id, host)
    png_bytes = SecurityService.generate_qr_png_bytes(verify_url)

    return Response(
        content=png_bytes,
        media_type="image/png",
        headers={
            "Cache-Control": "public, max-age=86400",
            "Content-Disposition": f'inline; filename="{product.id}_qr.png"'
        }
    )

