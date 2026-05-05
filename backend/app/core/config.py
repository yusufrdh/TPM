"""
PillPal-AI — Application Settings
Loaded from environment variables / .env file.
"""

from pydantic_settings import BaseSettings
from pathlib import Path


class Settings(BaseSettings):
    # ── JWT ────────────────────────────────────────
    SECRET_KEY: str = "pillpal-dev-secret-key-2026"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours (1 day)

    # ── Database ───────────────────────────────────
    DATABASE_URL: str = "sqlite:///./pillpal.db"

    # ── Gemini AI ──────────────────────────────────
    GEMINI_API_KEY: str = ""

    # ── App Meta ───────────────────────────────────
    APP_NAME: str = "PillPal-AI"
    APP_VERSION: str = "0.1.0"

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
    }


settings = Settings()
