import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/session_manager.dart';
import '../../../data/local/database_helper.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final BiometricService _biometricService = BiometricService();
  final SessionManager _session = SessionManager();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  bool _isObscure = true;
  bool _isLoading = false;
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricLogin();
  }

  Future<void> _checkBiometricLogin() async {
    // Load session first (in case app just started)
    await _session.loadSession();
    
    // Check if there's a logged in user with biometric enabled
    final userId = _session.userId;
    if (userId == null) {
      setState(() => _showBiometricButton = false);
      return;
    }

    final isBiometricEnabled = await _dbHelper.isBiometricEnabled(userId);
    final isBiometricAvailable = await _biometricService.isBiometricAvailable();
    
    setState(() {
      _showBiometricButton = isBiometricEnabled && isBiometricAvailable;
    });
    
    print('🔐 Biometric login available: $_showBiometricButton (userId: $userId, enabled: $isBiometricEnabled, available: $isBiometricAvailable)');
  }

  Future<void> _handleBiometricLogin() async {
    final userId = _session.userId;
    if (userId == null) {
      _showSnackBar('Tidak ada user yang tersimpan', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final authenticated = await _biometricService.authenticateForLogin();
    
    if (authenticated) {
      // Biometric authentication successful
      // Session sudah di-load dari SharedPreferences di initState
      // Tinggal navigate ke home
      if (!mounted) return;
      _showSnackBar('Login berhasil! Selamat datang ${_session.userName} 👋');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar('Autentikasi biometrik gagal', isError: true);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Username dan password harus diisi', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.login(
      username: username,
      password: password,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      _showSnackBar('Login berhasil! Selamat datang 👋');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar(result['message'] ?? 'Login gagal', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity, height: double.infinity,
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.teal.shade400, Colors.teal.shade900])),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30.0),
                child: Container(
                  padding: const EdgeInsets.all(25.0),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle), child: Icon(Icons.medication_liquid_rounded, size: 60, color: Colors.teal.shade700)),
                      const SizedBox(height: 20),
                      const Text('MedRemind Pro', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: 1)),
                      const Text('Asisten Kesehatan Pintar Anda', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 35),

                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(hintText: 'Username', prefixIcon: const Icon(Icons.person_outline), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        onSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          hintText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _isObscure = !_isObscure)),
                          filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // --- TOMBOL LUPA PASSWORD AKTIF ---
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                          child: const Text('Lupa Password?', style: TextStyle(color: Colors.teal, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 5),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text('MASUK KE DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                      
                      // --- BIOMETRIC LOGIN BUTTON ---
                      if (_showBiometricButton) ...[
                        const SizedBox(height: 15),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('atau', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity, height: 55,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleBiometricLogin,
                            icon: const Icon(Icons.fingerprint, size: 28),
                            label: const Text('Login dengan Sidik Jari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade700,
                              side: BorderSide(color: Colors.teal.shade700, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // --- TOMBOL DAFTAR AKTIF ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Belum punya akun? ", style: TextStyle(fontSize: 12)),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                            child: const Text("Daftar Sekarang", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}