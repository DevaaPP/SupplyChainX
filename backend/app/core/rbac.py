from enum import Enum
from typing import List, Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db.database import get_db

security_bearer = HTTPBearer(auto_error=False)

class UserRole(str, Enum):
    MANUFACTURER = "manufacturer"
    DISTRIBUTOR = "distributor"
    WAREHOUSE = "warehouse"
    RETAILER = "retailer"
    CUSTOMER = "customer"
    ADMIN = "admin"

def get_current_user_payload(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_bearer)
) -> Optional[dict]:
    if not credentials:
        return None
    token = credentials.credentials
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload

def get_current_user(
    payload: dict = Depends(get_current_user_payload),
    db: Session = Depends(get_db)
):
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user_id = payload.get("sub")
    from app.models.user import User
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or deactivated",
        )
    return user

def require_roles(allowed_roles: List[UserRole]):
    def role_checker(user = Depends(get_current_user)):
        if user.role not in [r.value for r in allowed_roles] and user.role != UserRole.ADMIN.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Requires one of: {[r.value for r in allowed_roles]}",
            )
        return user
    return role_checker
