import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/session_manager.dart';
import '../../../data/local/database_helper.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true; // Toggle antara Login dan Register
  bool _isObscure = true;
  bool _isLoading = false;
  bool _showBiometricButton = false;

  // Controllers untuk Login
  final TextEditingController _loginUsernameController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Controllers untuk Register
  final TextEditingController _registerFullNameController = TextEditingController();
  final TextEditingController _registerUsernameController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerPasswordController = TextEditingController();

  final ApiService _apiService = ApiService();
  final BiometricService _biometricService = BiometricService();
  final SessionManager _session = SessionManager();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _checkBiometricLogin();
  }

  Future<void> _checkBiometricLogin() async {
    // Load session first (in case app just started)
    await _session.loadSession();
    
    // Check if there's a logged in user with biometric enabled
    // Gunakan last user ID jika session sudah di-clear (setelah logout)
    int? userId = _session.userId;
    if (userId == null) {
      userId = await _session.getLastUserId();
    }
    
    if (userId == null) {
      setState(() => _showBiometricButton = false);
      print('🔐 No user ID found, hiding biometric button');
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
    // Gunakan last user ID jika session sudah di-clear
    int? userId = _session.userId;
    if (userId == null) {
      userId = await _session.getLastUserId();
    }
    
    if (userId == null) {
      _showSnackBar('Tidak ada user yang tersimpan', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Authenticate dengan biometric
    final authenticated = await _biometricService.authenticateForLogin();
    
    if (authenticated) {
      // Biometric authentication successful
      // Load saved credentials
      final credentials = await _session.getSavedCredentials();
      
      if (credentials == null) {
        if (!mounted) return;
        _showSnackBar('Credentials tidak ditemukan. Silakan login dengan username & password.', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      
      // Login dengan saved credentials
      final result = await _apiService.login(
        username: credentials['username']!,
        password: credentials['password']!,
      );
      
      if (result['success'] == true) {
        if (!mounted) return;
        _showSnackBar('Login berhasil! Selamat datang ${_session.userName} 👋');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showSnackBar(result['message'] ?? 'Login gagal', isError: true);
      }
    } else {
      _showSnackBar('Autentikasi sidik jari gagal', isError: true);
    }

    setState(() => _isLoading = false);
  }

  // Handle Login
  Future<void> _handleLogin() async {
    final username = _loginUsernameController.text.trim();
    final password = _loginPasswordController.text.trim();

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
      // Save credentials untuk biometric login
      await _session.saveCredentials(username, password);
      
      if (!mounted) return;
      _showSnackBar('Login berhasil! Selamat datang 👋');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar(result['message'] ?? 'Login gagal', isError: true);
    }
  }

  // Handle Register
  Future<void> _handleRegister() async {
    final fullName = _registerFullNameController.text.trim();
    final username = _registerUsernameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();

    if (fullName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Semua field harus diisi', isError: true);
      return;
    }

    if (username.length < 3) {
      _showSnackBar('Username minimal 3 karakter', isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password minimal 6 karakter', isError: true);
      return;
    }

    if (!email.contains('@')) {
      _showSnackBar('Email tidak valid', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.register(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      _showSnackBar(result['message'] ?? 'Registrasi berhasil! Silakan login.');
      // Switch ke mode login setelah berhasil register
      setState(() {
        _isLoginMode = true;
        _clearRegisterFields();
      });
    } else {
      _showSnackBar(result['message'] ?? 'Registrasi gagal', isError: true);
    }
  }

  void _clearRegisterFields() {
    _registerFullNameController.clear();
    _registerUsernameController.clear();
    _registerEmailController.clear();
    _registerPasswordController.clear();
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
      backgroundColor: const Color(0xFFB8E6E1), // Light teal background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.medication_liquid_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App Name
                  const Text(
                    'MedRemind Pro',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your health, expertly managed',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Toggle Button (Login / Register)
                  _buildToggleButton(),
                  const SizedBox(height: 30),

                  // Form Fields (Login atau Register)
                  _isLoginMode ? _buildLoginForm() : _buildRegisterForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Toggle Button antara Login dan Register
  Widget _buildToggleButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginMode = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _isLoginMode ? Colors.teal.shade600 : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: _isLoginMode ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginMode = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_isLoginMode ? Colors.teal.shade600 : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Register',
                  style: TextStyle(
                    color: !_isLoginMode ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Form Login
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Username Field
        const Text(
          'USERNAME',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _loginUsernameController,
          decoration: InputDecoration(
            hintText: 'john.doe',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.alternate_email, color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        const SizedBox(height: 20),

        // Password Field
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PASSWORD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
              ),
              child: Text(
                'FORGOT?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _loginPasswordController,
          obscureText: _isObscure,
          onSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
            suffixIcon: IconButton(
              icon: Icon(
                _isObscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        const SizedBox(height: 30),

        // Secure Login Button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Secure Login',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 30),

        // Quick Access - Hanya tampilkan jika biometric enabled
        if (_showBiometricButton) ...[
          const Center(
            child: Text(
              'QUICK ACCESS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: GestureDetector(
              onTap: _isLoading ? null : _handleBiometricLogin,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.teal.shade600, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 32,
                  color: Colors.teal.shade600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Form Register
  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name Field
        const Text(
          'FULL NAME',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _registerFullNameController,
          decoration: InputDecoration(
            hintText: 'John Doe',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        const SizedBox(height: 20),

        // Username Field
        const Text(
          'USERNAME',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _registerUsernameController,
          decoration: InputDecoration(
            hintText: 'john.doe',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.account_circle_outlined, color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        const SizedBox(height: 20),

        // Email Field
        const Text(
          'EMAIL ADDRESS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _registerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'john.doe@medical.com',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.alternate_email, color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        const SizedBox(height: 20),

        // Password Field
        const Text(
          'PASSWORD',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _registerPasswordController,
          obscureText: _isObscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
            suffixIcon: IconButton(
              icon: Icon(
                _isObscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        const SizedBox(height: 30),

        // Register Button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _registerFullNameController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }
}
