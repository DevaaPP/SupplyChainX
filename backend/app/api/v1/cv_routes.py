from fastapi import APIRouter
from app.schemas.cv import ImageCVVerifyRequest, ImageCVVerifyResponse
from app.services.cv_service import CVService

router = APIRouter(prefix="/cv", tags=["Computer Vision & NFC Multi-Modal Verification"])

@router.post("/verify", response_model=ImageCVVerifyResponse)
def verify_packaging_and_nfc(req: ImageCVVerifyRequest):
    """Computer Vision packaging image label verification & NFC tap validation."""
    return CVService.verify_packaging_image(req)
