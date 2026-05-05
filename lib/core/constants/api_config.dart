/// Konfigurasi koneksi ke backend FastAPI (PillPal-AI).
///
/// Ubah [baseUrl] sesuai alamat server backend:
///   - Android Emulator  → http://10.0.2.2:8000
///   - iOS Simulator      → http://localhost:8000
///   - Device fisik (WiFi) → http://<IP-LAN-PC>:8000
class ApiConfig {
  // ── Base URL ──────────────────────────────────
  // Gunakan IP WiFi Laptop agar bisa diakses dari HP fisik
  static const String baseUrl = 'http://10.253.248.25:8000';

  // ── Auth Endpoints ────────────────────────────
  static const String registerUrl = '$baseUrl/api/auth/register';
  static const String loginUrl = '$baseUrl/api/auth/login/json';
  static const String meUrl = '$baseUrl/api/auth/me';

  // ── Service Endpoints ─────────────────────────
  static const String pingGeminiUrl = '$baseUrl/api/services/ping-gemini';
  static const String pingRxnormUrl = '$baseUrl/api/services/ping-rxnorm';
  static const String searchDrugUrl = '$baseUrl/api/services/search-drug';
  static const String askGeminiUrl = '$baseUrl/api/services/ask-gemini';

  // ── Medications Endpoints ─────────────────────
  /// F-04B: Parsing teks alami jadwal obat via Gemini
  static const String parseScheduleUrl = '$baseUrl/api/medications/parse-schedule';
  /// F-07: Rangkuman medis obat (RxNorm + OpenFDA + Gemini)
  static const String drugSummaryUrl = '$baseUrl/api/medications/drug-summary';
}
