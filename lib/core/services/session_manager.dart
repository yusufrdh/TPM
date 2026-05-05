import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manajer sesi dengan persistensi menggunakan SharedPreferences
/// untuk menyimpan JWT token dan data profil user yang sedang login.
///
/// Session akan tetap tersimpan meskipun aplikasi ditutup.
/// Credentials (username & password) disimpan secara encrypted di Secure Storage.
class SessionManager {
  // Singleton
  SessionManager._internal();
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;

  // SharedPreferences keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyCurrentUser = 'current_user';
  static const String _keyLastUserId = 'last_user_id'; // User ID terakhir yang login (tidak di-clear saat logout)

  // Secure Storage keys (untuk credentials)
  static const String _keySecureUsername = 'secure_username';
  static const String _keySecurePassword = 'secure_password';

  // Secure Storage instance
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ── Data Sesi (in-memory cache) ───────────────
  String? _accessToken;
  Map<String, dynamic>? _currentUser;

  // ── Token ─────────────────────────────────────
  String? get accessToken => _accessToken;

  Future<void> setToken(String token) async {
    _accessToken = token;
    
    // Simpan ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, token);
    print('✅ Token saved to SharedPreferences');
  }

  bool get isLoggedIn => _accessToken != null;

  // ── User Profile ──────────────────────────────
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<void> setUser(Map<String, dynamic> user) async {
    _currentUser = user;
    
    // Simpan ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, jsonEncode(user));
    
    // Simpan last user ID (untuk biometric login)
    final userId = user['id'];
    if (userId != null) {
      await prefs.setInt(_keyLastUserId, userId);
      print('✅ Last user ID saved: $userId');
    }
    
    print('✅ User data saved to SharedPreferences');
  }

  String get userName => _currentUser?['full_name'] ?? _currentUser?['username'] ?? 'User';
  String get userEmail => _currentUser?['email'] ?? '';
  String get username => _currentUser?['username'] ?? '';
  int? get userId => _currentUser?['id'];

  // ── Load Session ──────────────────────────────
  /// Load session dari SharedPreferences saat app start
  /// Return true jika session berhasil di-load
  Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load token
      final token = prefs.getString(_keyAccessToken);
      if (token == null) {
        print('⚠️ No saved token found');
        return false;
      }
      
      // Load user data
      final userJson = prefs.getString(_keyCurrentUser);
      if (userJson == null) {
        print('⚠️ No saved user data found');
        return false;
      }
      
      // Restore session
      _accessToken = token;
      _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
      
      print('✅ Session loaded from SharedPreferences');
      print('   → User: ${_currentUser?['username']} (ID: ${_currentUser?['id']})');
      
      return true;
    } catch (e) {
      print('❌ Error loading session: $e');
      return false;
    }
  }

  // ── Logout ────────────────────────────────────
  Future<void> clear() async {
    _accessToken = null;
    _currentUser = null;
    
    // Hapus dari SharedPreferences (KECUALI last_user_id untuk biometric)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyCurrentUser);
    // JANGAN hapus _keyLastUserId agar biometric login tetap bisa cek
    print('✅ Session cleared from SharedPreferences (last_user_id retained)');
  }

  // ── Get Last User ID (untuk biometric login) ──
  Future<int?> getLastUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyLastUserId);
    } catch (e) {
      print('❌ Error getting last user ID: $e');
      return null;
    }
  }

  // ── Save Credentials (untuk biometric login) ──
  Future<void> saveCredentials(String username, String password) async {
    try {
      await _secureStorage.write(key: _keySecureUsername, value: username);
      await _secureStorage.write(key: _keySecurePassword, value: password);
      print('✅ Credentials saved to Secure Storage');
    } catch (e) {
      print('❌ Error saving credentials: $e');
    }
  }

  // ── Get Saved Credentials ──
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final username = await _secureStorage.read(key: _keySecureUsername);
      final password = await _secureStorage.read(key: _keySecurePassword);
      
      if (username != null && password != null) {
        print('✅ Credentials loaded from Secure Storage');
        return {'username': username, 'password': password};
      }
      
      print('⚠️ No saved credentials found');
      return null;
    } catch (e) {
      print('❌ Error loading credentials: $e');
      return null;
    }
  }

  // ── Delete Credentials ──
  Future<void> deleteCredentials() async {
    try {
      await _secureStorage.delete(key: _keySecureUsername);
      await _secureStorage.delete(key: _keySecurePassword);
      print('✅ Credentials deleted from Secure Storage');
    } catch (e) {
      print('❌ Error deleting credentials: $e');
    }
  }
}
