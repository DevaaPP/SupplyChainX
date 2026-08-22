from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from app.db.database import get_db
from app.models.user import User
from app.schemas.auth import UserLogin, UserRegister, UserResponse, Token
from app.core.security import verify_password, get_password_hash, create_access_token
from app.core.rbac import get_current_user
from app.services.audit_service import AuditService

router = APIRouter(prefix="/auth", tags=["Authentication & RBAC"])

@router.post("/register", response_model=Token)
def register(user_in: UserRegister, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == user_in.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email address already registered in terminal network"
        )
    
    hashed_pwd = get_password_hash(user_in.password)
    user = User(
        email=user_in.email,
        hashed_password=hashed_pwd,
        display_name=user_in.display_name,
        role=user_in.role.lower(),
        organization=user_in.organization,
        created_at=datetime.now(timezone.utc),
        last_login=datetime.now(timezone.utc)
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    AuditService.log_event(
        db=db,
        event_type="auth_register",
        severity="info",
        actor_id=user.id,
        actor_email=user.email,
        actor_role=user.role,
        description=f"New operator account provisioned: {user.display_name} ({user.role})"
    )

    token = create_access_token(subject=user.id, role=user.role)
    return Token(access_token=token, token_type="bearer", user=UserResponse.model_validate(user))

@router.post("/login", response_model=Token)
def login(login_in: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == login_in.email.strip().lower()).first()
    
    # Check credentials
    if not user or not verify_password(login_in.password, user.hashed_password):
        AuditService.log_event(
            db=db,
            event_type="auth_failure",
            severity="medium",
            actor_email=login_in.email,
            description=f"Failed authentication attempt for email {login_in.email}"
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

    user.last_login = datetime.now(timezone.utc)
    db.commit()

    AuditService.log_event(
        db=db,
        event_type="auth_success",
        severity="info",
        actor_id=user.id,
        actor_email=user.email,
        actor_role=user.role,
        description=f"Operator {user.display_name} logged in successfully"
    )

    token = create_access_token(subject=user.id, role=user.role)
    return Token(access_token=token, token_type="bearer", user=UserResponse.model_validate(user))

@router.get("/me", response_model=UserResponse)
def get_me(user: User = Depends(get_current_user)):
    return UserResponse.model_validate(user)

@router.post("/toggle-2fa")
def toggle_2fa(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    user.is_2fa_enabled = not user.is_2fa_enabled
    db.commit()
    return {"status": "success", "is_2fa_enabled": user.is_2fa_enabled}
