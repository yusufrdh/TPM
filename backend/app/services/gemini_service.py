"""
PillPal-AI — Gemini AI Service
Test connection to Google Gemini API.
"""

import google.generativeai as genai

from app.core.config import settings


def test_connection() -> dict:
    """
    Send a simple prompt to Gemini to verify the API key works.
    Returns a dict with status and the model's response text.
    """
    if not settings.GEMINI_API_KEY:
        return {
            "status": "error",
            "message": "GEMINI_API_KEY belum dikonfigurasi di file .env",
        }

    try:
        genai.configure(api_key=settings.GEMINI_API_KEY)
        model = genai.GenerativeModel("gemini-3.1-flash-lite-preview")
        response = model.generate_content(
            "Jawab dalam satu kalimat singkat: Apa itu PillPal?"
        )
        return {
            "status": "ok",
            "model": "gemini-3.1-flash-lite-preview",
            "response": response.text,
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e),
        }


def ask_question(question: str) -> dict:
    """
    Send a health/medication question to Gemini AI and return the response.
    """
    if not settings.GEMINI_API_KEY:
        return {
            "status": "error",
            "message": "GEMINI_API_KEY belum dikonfigurasi di file .env",
        }

    try:
        genai.configure(api_key=settings.GEMINI_API_KEY)
        model = genai.GenerativeModel("gemini-3.1-flash-lite-preview")

        # System prompt agar Gemini menjawab sebagai asisten kesehatan
        system_prompt = (
            "Kamu adalah PillPal-AI, asisten kesehatan pintar berbahasa Indonesia. "
            "Tugasmu adalah menjawab pertanyaan seputar obat-obatan, dosis, efek samping, "
            "interaksi obat, dan tips kesehatan. Jawab dengan singkat, jelas, dan informatif. "
            "Gunakan format Markdown untuk membuat jawaban lebih mudah dibaca: "
            "gunakan **bold** untuk judul/poin penting, gunakan bullet points (- atau *) untuk list, "
            "gunakan numbering (1. 2. 3.) untuk langkah-langkah, dan gunakan paragraf terpisah untuk topik berbeda. "
            "Selalu ingatkan pengguna untuk berkonsultasi dengan dokter atau apoteker "
            "untuk keputusan medis yang serius."
        )

        full_prompt = f"{system_prompt}\n\nPertanyaan pengguna: {question}"
        response = model.generate_content(full_prompt)

        return {
            "status": "ok",
            "question": question,
            "answer": response.text,
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e),
        }
