"""
PillPal-AI — Auth API Routes
POST /api/auth/register  → Register a new user
POST /api/auth/login     → Login and get JWT token
GET  /api/auth/me        → Get current user profile (protected)
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    get_current_user,
)
from app.models.user import User
from app.schemas.auth import (
    UserCreate,
    UserLogin,
    Token,
    UserResponse,
    MessageResponse,
)

router = APIRouter(prefix="/api/auth", tags=["🔐 Authentication"])


# ── Register ──────────────────────────────────────
@router.post(
    "/register",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrasi user baru",
)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    """
    Buat akun baru. Username dan email harus unik.
    Password akan di-hash menggunakan **PBKDF2-SHA256**.
    """
    # Check duplicate username
    if db.query(User).filter(User.username == payload.username).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Username '{payload.username}' sudah terdaftar",
        )

    # Check duplicate email
    if db.query(User).filter(User.email == payload.email).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Email '{payload.email}' sudah terdaftar",
        )

    # Create user with hashed password
    new_user = User(
        username=payload.username,
        email=payload.email,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return MessageResponse(
        message="Registrasi berhasil! Silakan login.",
        detail={"user_id": new_user.id, "username": new_user.username},
    )


# ── Login (OAuth2 form — untuk Swagger Authorize) ─
@router.post(
    "/login",
    response_model=Token,
    summary="Login dan dapatkan JWT token",
)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    """
    Login dengan username & password (form-data).
    Digunakan oleh **Swagger Authorize** dan standar OAuth2.
    Mengembalikan **JWT access token** jika berhasil.
    """
    user = db.query(User).filter(User.username == form_data.username).first()

    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Username atau password salah",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(data={"sub": user.username})

    return Token(access_token=access_token)


# ── Login JSON (untuk Flutter app) ────────────────
@router.post(
    "/login/json",
    response_model=Token,
    summary="Login via JSON body (untuk mobile app)",
)
def login_json(payload: UserLogin, db: Session = Depends(get_db)):
    """
    Login dengan JSON body `{"username": "...", "password": "..."}`.
    Endpoint ini untuk **Flutter/mobile app**.
    """
    user = db.query(User).filter(User.username == payload.username).first()

    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Username atau password salah",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(data={"sub": user.username})

    return Token(access_token=access_token)


# ── Current User Profile ─────────────────────────
@router.get(
    "/me",
    response_model=UserResponse,
    summary="Profil user yang sedang login",
)
def get_me(current_user: User = Depends(get_current_user)):
    """
    Endpoint **terproteksi**. Memerlukan header:
    `Authorization: Bearer <token>`
    """
    return current_user


# ── Check Token Validity ──────────────────────────
@router.get(
    "/check-token",
    summary="Cek apakah token masih valid",
)
def check_token(current_user: User = Depends(get_current_user)):
    """
    Endpoint untuk mengecek apakah token masih valid.
    Jika token valid, return user info.
    Jika token expired/invalid, return 401.
    """
    return {
        "status": "ok",
        "message": "Token masih valid",
        "user": {
            "id": current_user.id,
            "username": current_user.username,
            "email": current_user.email,
        },
    }


# ── Refresh Token ─────────────────────────────────
@router.post(
    "/refresh",
    response_model=Token,
    summary="Refresh JWT token",
)
def refresh_token(current_user: User = Depends(get_current_user)):
    """
    Generate token baru untuk user yang sedang login.
    Gunakan endpoint ini jika token hampir expired.
    """
    access_token = create_access_token(data={"sub": current_user.username})
    return Token(access_token=access_token)
