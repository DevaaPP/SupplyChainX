import random
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.models.product import Product
from app.schemas.product import ProductCreate, ProductResponse, QRDataPayload
from app.core.rbac import get_current_user, require_roles, UserRole
from app.services.security_service import SecurityService
from app.services.custody_service import CustodyService

router = APIRouter(prefix="/products", tags=["Product Registry & HMAC Security"])

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
    return [ProductResponse.model_validate(p) for p in products]

@router.get("/{product_id}", response_model=ProductResponse)
def get_product(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Product {product_id} not found")
    return ProductResponse.model_validate(product)

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

    return ProductResponse.model_validate(product)

@router.get("/{product_id}/qr", response_model=QRDataPayload)
def get_product_qr(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    raw_qr = SecurityService.create_qr_payload(
        product_id=product.id,
        name=product.name,
        batch_number=product.batch_number,
        manufacturer_name=product.manufacturer_name,
        created_at_iso=product.created_at.isoformat(),
        signature=product.hmac_signature
    )

    return QRDataPayload(
        product_id=product.id,
        name=product.name,
        batch_number=product.batch_number,
        manufacturer=product.manufacturer_name,
        timestamp=product.created_at.isoformat(),
        hmac_signature=product.hmac_signature,
        raw_qr_string=raw_qr
    )
