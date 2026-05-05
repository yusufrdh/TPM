import 'package:flutter/material.dart';
// Import tema kustom agar UI terlihat premium
import 'core/constants/app_theme.dart';
// Import semua screen utama
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/main_screen.dart';
// Import notification service
import 'core/services/notification_service.dart';
// Import session manager
import 'core/services/session_manager.dart';

void main() async {
  // Memastikan binding Flutter terinisialisasi sebelum menjalankan app
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService().initialize();
  
  // Load saved session
  final sessionManager = SessionManager();
  await sessionManager.loadSession();
  
  runApp(const TugasAkhirApp());
}

class TugasAkhirApp extends StatelessWidget {
  const TugasAkhirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedRemind Pro',
      
      // MENGGUNAKAN TEMA PREMIUM
      // Pastikan file app_theme.dart sudah kamu buat dengan class AppTheme
      theme: AppTheme.lightTheme,
      
      // SISTEM NAVIGASI (ROUTES)
      // initialRoute '/' akan membuka SplashScreen untuk cek session
      initialRoute: '/',
      routes: {
        // Splash screen untuk cek session
        '/': (context) => const SplashScreen(),
        
        // Halaman Auth (Login/Register dalam satu screen)
        '/auth': (context) => const AuthScreen(),
        
        // Halaman Login lama (masih bisa diakses jika diperlukan)
        '/login': (context) => const LoginScreen(),
        
        // Halaman Dashboard Utama (Gunakan MainScreen tanpa const karena ada Timer)
        '/home': (context) => MainScreen(),
      },
      
      // Fallback jika terjadi kesalahan navigasi
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const AuthScreen(),
        );
      },
    );
  }
}

/// Splash screen untuk cek session dan navigate ke home atau auth
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Delay sedikit untuk splash effect
    await Future.delayed(const Duration(milliseconds: 500));
    
    final sessionManager = SessionManager();
    
    if (!mounted) return;
    
    // Jika ada session, langsung ke home
    if (sessionManager.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Jika tidak ada session, ke auth screen
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade400, Colors.teal.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_liquid_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'MedRemind Pro',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Asisten Kesehatan Pintar Anda',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}