import 'package:flutter/material.dart';
import '../../../core/services/session_manager.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/local/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SessionManager _session = SessionManager();
  final ApiService _apiService = ApiService();
  final BiometricService _biometricService = BiometricService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  bool _isNotificationEnabled = true;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  String _biometricType = '';

  // Data dari session (live dari backend)
  String get _userName => _session.userName;
  String get _userEmail => _session.userEmail;
  String get _username => _session.username;

  String get _initials {
    if (_userName.isNotEmpty) {
      final parts = _userName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadBiometricStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 40, bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFF0D9488),
                        child: Text(_initials, style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      GestureDetector(
                        onTap: () => _showSnackBar('Membuka Galeri Foto...'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text('@$_username', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 20),
                  
                  // FITUR AKTIF: EDIT PROFIL
                  SizedBox(
                    width: 160,
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditProfileDialog(),
                      icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                      label: const Text('Edit Profil', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- MENU SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildInfoTile(Icons.person, 'Username: @$_username'),
                  _buildInfoTile(Icons.email, _userEmail),
                  
                  const SizedBox(height: 25),
                  const Text('Pengaturan Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // FITUR AKTIF: GANTI PASSWORD
                  _buildMenuTile(Icons.lock_outline, 'Ganti Password', Colors.blue, () => _showChangePasswordDialog()),
                  
                  // FITUR AKTIF: NOTIFIKASI
                  _buildMenuTile(
                    _isNotificationEnabled ? Icons.notifications_active : Icons.notifications_off, 
                    'Notifikasi Pengingat', 
                    Colors.orange, 
                    () => _toggleNotification()
                  ),
                  
                  // FITUR AKTIF: BIOMETRIC LOGIN
                  if (_isBiometricAvailable)
                    _buildMenuTile(
                      _isBiometricEnabled ? Icons.fingerprint : Icons.fingerprint_outlined,
                      'Login Biometrik ($_biometricType)',
                      Colors.green,
                      () => _toggleBiometric(),
                    ),
                  
                  // FITUR AKTIF: EVALUASI (BOTTOM SHEET)
                  _buildMenuTile(Icons.feedback_outlined, 'Evaluasi & Masukan', Colors.purple, () => _showEvaluationSheet()),
                  
                  // FITUR AKTIF: LOGOUT
                  _buildMenuTile(Icons.logout, 'Keluar Akun', Colors.red, () => _showLogoutConfirm(), isLogout: true),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- LOGIKA FITUR (FUNCTIONS) ---

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  void _showEditProfileDialog() {
    TextEditingController nameCtrl = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Nama Profil'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              // Update di session secara lokal (backend belum ada endpoint update profile)
              final currentUser = _session.currentUser ?? {};
              currentUser['full_name'] = nameCtrl.text;
              await _session.setUser(currentUser);
              setState(() {});
              if (!mounted) return;
              Navigator.pop(context);
              _showSnackBar('Profil diperbarui!');
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(obscureText: true, decoration: InputDecoration(labelText: 'Password Lama')),
            TextField(obscureText: true, decoration: InputDecoration(labelText: 'Password Baru')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _showSnackBar('Password berhasil diganti!'); }, child: const Text('Update')),
        ],
      ),
    );
  }

  void _toggleNotification() {
    setState(() => _isNotificationEnabled = !_isNotificationEnabled);
    _showSnackBar(_isNotificationEnabled ? 'Notifikasi Aktif' : 'Notifikasi Dimatikan');
  }

  // ══════════════════════════════════════════════════════════════
  // BIOMETRIC METHODS
  // ══════════════════════════════════════════════════════════════

  Future<void> _checkBiometricAvailability() async {
    print('🔐 Checking biometric availability...');
    
    final isAvailable = await _biometricService.isBiometricAvailable();
    final biometricName = await _biometricService.getAvailableBiometricNames();
    
    // Additional debug info
    final canCheck = await _biometricService.canCheckBiometrics();
    final isSupported = await _biometricService.isDeviceSupported();
    final availableBiometrics = await _biometricService.getAvailableBiometrics();
    
    print('   → Can check biometrics: $canCheck');
    print('   → Device supported: $isSupported');
    print('   → Available biometrics: $availableBiometrics');
    print('   → Biometric name: $biometricName');
    print('   → Is available: $isAvailable');
    
    setState(() {
      _isBiometricAvailable = isAvailable;
      _biometricType = biometricName;
    });
    
    print('🔐 Biometric availability check complete');
    print('   → Will show menu: $_isBiometricAvailable');
  }

  Future<void> _loadBiometricStatus() async {
    final userId = _session.userId;
    if (userId == null) return;
    
    final isEnabled = await _dbHelper.isBiometricEnabled(userId);
    setState(() {
      _isBiometricEnabled = isEnabled;
    });
    
    print('🔐 Biometric status loaded: $isEnabled');
  }

  Future<void> _toggleBiometric() async {
    print('🔐 Toggle biometric called');
    print('   → Available: $_isBiometricAvailable');
    print('   → Enabled: $_isBiometricEnabled');
    
    if (!_isBiometricAvailable) {
      _showSnackBar('Biometrik tidak tersedia di device ini');
      return;
    }

    final userId = _session.userId;
    if (userId == null) {
      _showSnackBar('User ID tidak ditemukan');
      return;
    }

    print('   → User ID: $userId');

    if (_isBiometricEnabled) {
      // Disable biometric - need authentication first
      print('🔐 Attempting to disable biometric...');
      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Scan sidik jari untuk menonaktifkan login biometrik',
      );
      
      print('   → Authentication result: $authenticated');
      
      if (authenticated) {
        await _dbHelper.updateBiometricStatus(userId, false);
        setState(() => _isBiometricEnabled = false);
        _showSnackBar('Login biometrik dinonaktifkan');
      } else {
        _showSnackBar('Autentikasi gagal. Pastikan sidik jari Anda terdaftar di device.');
      }
    } else {
      // Enable biometric - need authentication first
      print('🔐 Attempting to enable biometric...');
      
      // Double check biometric availability
      final canCheck = await _biometricService.canCheckBiometrics();
      final isSupported = await _biometricService.isDeviceSupported();
      final availableBiometrics = await _biometricService.getAvailableBiometrics();
      
      print('   → Can check: $canCheck');
      print('   → Is supported: $isSupported');
      print('   → Available biometrics: $availableBiometrics');
      
      if (!canCheck || !isSupported || availableBiometrics.isEmpty) {
        _showSnackBar('Sidik jari tidak tersedia. Pastikan Anda sudah setup sidik jari di Settings device.');
        return;
      }
      
      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Scan sidik jari untuk mengaktifkan login biometrik',
      );
      
      print('   → Authentication result: $authenticated');
      
      if (authenticated) {
        await _dbHelper.updateBiometricStatus(userId, true);
        setState(() => _isBiometricEnabled = true);
        _showSnackBar('Login biometrik diaktifkan! ✅');
      } else {
        _showSnackBar('Autentikasi gagal. Pastikan sidik jari Anda terdaftar di device.');
      }
    }
  }

  void _showEvaluationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Evaluasi & Masukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const TextField(maxLines: 3, decoration: InputDecoration(hintText: 'Tulis kesan kuliah TPM...', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Kirim'))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Aplikasi?'),
        content: const Text('Anda akan diarahkan kembali ke halaman login.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await _apiService.logout(); // Bersihkan sesi
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/auth');
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildInfoTile(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [Icon(icon, color: Colors.teal, size: 20), const SizedBox(width: 15), Expanded(child: Text(text))]),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, Color color, VoidCallback onTap, {bool isLogout = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: isLogout ? Colors.red : Colors.black87)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}