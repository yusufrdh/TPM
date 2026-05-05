import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// Service untuk mengelola autentikasi biometrik
/// Menggunakan local_auth untuk fingerprint/face recognition
class BiometricService {
  // Singleton pattern
  BiometricService._internal();
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();

  // ══════════════════════════════════════════════════════════════
  // CHECK BIOMETRIC AVAILABILITY
  // ══════════════════════════════════════════════════════════════

  /// Check if device supports biometric authentication
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('❌ Error checking biometrics: $e');
      return false;
    }
  }

  /// Check if device has biometric hardware
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('❌ Error checking device support: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  /// Returns: [BiometricType.face, BiometricType.fingerprint, etc.]
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('❌ Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if biometric is available and enrolled
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await canCheckBiometrics();
      final isSupported = await isDeviceSupported();
      final availableBiometrics = await getAvailableBiometrics();
      
      // Filter: hanya fingerprint yang diperbolehkan (tidak face/iris)
      final hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint) ||
                             availableBiometrics.contains(BiometricType.strong) ||
                             availableBiometrics.contains(BiometricType.weak);
      
      print('🔐 Biometric check: canCheck=$canCheck, isSupported=$isSupported, hasFingerprint=$hasFingerprint');
      
      return canCheck && isSupported && hasFingerprint;
    } catch (e) {
      print('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // AUTHENTICATE
  // ══════════════════════════════════════════════════════════════

  /// Authenticate user with biometric
  /// 
  /// Returns:
  /// - true: Authentication successful
  /// - false: Authentication failed or cancelled
  Future<bool> authenticate({
    String localizedReason = 'Verifikasi identitas Anda untuk melanjutkan',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      print('🔐 Starting biometric authentication...');
      print('   → Reason: $localizedReason');
      
      // Check if biometric is available
      final isAvailable = await isBiometricAvailable();
      print('   → Is available: $isAvailable');
      
      if (!isAvailable) {
        print('⚠️ Biometric not available on this device');
        return false;
      }

      // Authenticate
      print('   → Calling authenticate...');
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true, // ONLY fingerprint, no PIN/Pattern fallback
        ),
      );

      if (authenticated) {
        print('✅ Biometric authentication successful');
      } else {
        print('❌ Biometric authentication failed (user cancelled or failed)');
      }

      return authenticated;
    } catch (e) {
      print('❌ Exception during authentication: $e');
      print('   → Type: ${e.runtimeType}');
      
      // Handle specific errors
      final errorString = e.toString();
      if (errorString.contains(auth_error.notAvailable)) {
        print('⚠️ Biometric not available');
      } else if (errorString.contains(auth_error.notEnrolled)) {
        print('⚠️ No biometric enrolled');
      } else if (errorString.contains(auth_error.lockedOut)) {
        print('⚠️ Too many attempts, locked out');
      } else if (errorString.contains(auth_error.permanentlyLockedOut)) {
        print('⚠️ Permanently locked out');
      } else if (errorString.contains('PlatformException')) {
        print('⚠️ Platform exception: $errorString');
      }
      
      return false;
    }
  }

  /// Authenticate for login
  Future<bool> authenticateForLogin() async {
    return await authenticate(
      localizedReason: 'Scan sidik jari Anda untuk login',
      useErrorDialogs: true,
      stickyAuth: true,
    );
  }

  /// Authenticate for sensitive action
  Future<bool> authenticateForAction(String action) async {
    return await authenticate(
      localizedReason: 'Scan sidik jari untuk $action',
      useErrorDialogs: true,
      stickyAuth: false,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // UTILITY
  // ══════════════════════════════════════════════════════════════

  /// Get biometric type name for display
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Sidik Jari';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Biometrik Kuat';
      case BiometricType.weak:
        return 'Biometrik Lemah';
      default:
        return 'Biometrik';
    }
  }

  /// Get available biometric names as string
  Future<String> getAvailableBiometricNames() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.isEmpty) {
      return 'Tidak ada';
    }
    
    // Filter: hanya tampilkan fingerprint
    final fingerprintTypes = biometrics.where((type) => 
      type == BiometricType.fingerprint ||
      type == BiometricType.strong ||
      type == BiometricType.weak
    ).toList();
    
    if (fingerprintTypes.isEmpty) {
      return 'Tidak ada';
    }
    
    // Selalu return "Sidik Jari" untuk semua fingerprint types
    return 'Sidik Jari';
  }

  /// Stop authentication (cancel)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      print('🛑 Authentication stopped');
    } catch (e) {
      print('❌ Error stopping authentication: $e');
    }
  }
}
