import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import 'session_manager.dart';

/// Service utama untuk berkomunikasi dengan backend FastAPI (PillPal-AI).
///
/// Menyediakan method-method untuk:
/// - Register & Login (auth)
/// - Mengambil profil user (/me)
/// - Ping Gemini AI & RxNorm
/// - Search obat via RxNorm
class ApiService {
  final SessionManager _session = SessionManager();

  // ── Helper: Header dengan JWT ─────────────────
  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_session.accessToken}',
      };

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
      };

  // ════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════

  /// Register user baru.
  /// Mengembalikan `{'success': true, 'message': '...'}` atau
  /// `{'success': false, 'message': '...'}`.
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final body = {
        'username': username,
        'email': email,
        'password': password,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: _jsonHeaders,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Registrasi berhasil!'};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Registrasi gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  /// Login user dan simpan JWT token ke SessionManager.
  /// Mengembalikan `{'success': true}` atau `{'success': false, 'message': '...'}`.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final body = {
        'username': username,
        'password': password,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: _jsonHeaders,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan token
        await _session.setToken(data['access_token']);

        // Langsung fetch profil user
        await fetchMyProfile();

        return {'success': true};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  /// Ambil profil user yang sedang login (endpoint /me).
  Future<Map<String, dynamic>> fetchMyProfile() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.meUrl),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _session.setUser(data);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Gagal mengambil profil'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ════════════════════════════════════════════════
  // GEMINI AI
  // ════════════════════════════════════════════════

  /// Test koneksi ke Gemini AI (memerlukan login).
  Future<Map<String, dynamic>> pingGemini() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.pingGeminiUrl),
        headers: _authHeaders,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal terhubung: $e'};
    }
  }

  // ════════════════════════════════════════════════
  // RXNORM DRUG SEARCH
  // ════════════════════════════════════════════════

  /// Test koneksi ke RxNorm API.
  Future<Map<String, dynamic>> pingRxnorm() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.pingRxnormUrl),
        headers: _authHeaders,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal terhubung: $e'};
    }
  }

  /// Cari obat berdasarkan nama via RxNorm API.
  Future<Map<String, dynamic>> searchDrug(String name) async {
    try {
      final uri = Uri.parse(ApiConfig.searchDrugUrl).replace(
        queryParameters: {'name': name},
      );
      final response = await http.get(uri, headers: _authHeaders);
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal mencari obat: $e'};
    }
  }

  // ════════════════════════════════════════════════
  // GEMINI AI CHAT
  // ════════════════════════════════════════════════

  /// Kirim pertanyaan ke Gemini AI dan dapatkan jawaban.
  Future<Map<String, dynamic>> askGemini(String question) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.askGeminiUrl),
        headers: _authHeaders,
        body: jsonEncode({'question': question}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        // Jika ada error dari FastAPI (contoh: 422 Validation, 401 Unauthorized)
        return {
          'status': 'error', 
          'message': data['detail'] is List 
              ? 'Data tidak valid: ${data['detail'][0]['msg']}' 
              : data['detail'] ?? 'Error ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal menghubungi AI: $e'};
    }
  }

  // ════════════════════════════════════════════════
  // F-04B — PARSE SCHEDULE (LLM Natural Language)
  // ════════════════════════════════════════════════

  /// Parse teks alami jadwal obat via Gemini AI.
  ///
  /// [text] contoh: "Minum Paracetamol 500mg tiap 8 jam, stok 30 tablet"
  ///
  /// Return sukses: `{'status':'ok', 'data': {name, dosage, dosage_unit,
  ///   frequency_type, frequency_value, total_stock, time_intake}}`
  ///
  /// Terkait SKPL: F-04B
  Future<Map<String, dynamic>> parseSchedule(String text) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.parseScheduleUrl),
        headers: _authHeaders,
        body: jsonEncode({'text': text}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return data;
      return {
        'status': 'error',
        'message': data['detail'] ?? 'Gagal mem-parsing jadwal (${response.statusCode})',
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  // ════════════════════════════════════════════════
  // F-07 — DRUG SUMMARY (RxNorm + OpenFDA + Gemini)
  // ════════════════════════════════════════════════

  /// Dapatkan rangkuman medis obat yang dipersonalisasi.
  ///
  /// [drugName]      : Nama obat, contoh: "Paracetamol"
  /// [allergyProfile]: Profil alergi user dari SessionManager (boleh kosong)
  ///
  /// Return sukses: `{'status':'ok', 'drug_name':..., 'rxcui':...,
  ///   'summary':'...teks rangkuman...', 'data_source':...}`
  ///
  /// Terkait SKPL: F-07
  Future<Map<String, dynamic>> getDrugSummary({
    required String drugName,
    String allergyProfile = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.drugSummaryUrl),
        headers: _authHeaders,
        body: jsonEncode({
          'drug_name': drugName,
          'allergy_profile': allergyProfile,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return data;
      return {
        'status': 'error',
        'message': data['detail'] ?? 'Gagal mengambil rangkuman (${response.statusCode})',
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  // ════════════════════════════════════════════════
  // LOGOUT
  // ════════════════════════════════════════════════

  Future<void> logout() async {
    await _session.clear();
  }
}
