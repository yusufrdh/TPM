import 'package:flutter/material.dart';

import 'conversion_screen.dart';
import 'mini_game_screen.dart';
import 'health_articles_screen.dart';
import 'analytics_screen.dart';
import '../../pharmacy_map/screens/map_screen.dart';
// import 'history_screen.dart'; // Tetep di-comment biar aman

class ToolsMenuScreen extends StatelessWidget {
  const ToolsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: [
            // 1. MENU KONVERSI (GABUNGAN MATA UANG & WAKTU)
            _buildMenuCard(
              context,
              title: 'Waktu &\nMata Uang ',
              icon: Icons.sync, // Icon putaran panah biar melambangkan konversi
              color: const Color(0xFF2A9D8F),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConversionScreen())),
            ),
            
            // 2. MENU MINI GAME
            _buildMenuCard(
              context,
              title: 'Mini Game\nMed-Match',
              icon: Icons.sports_esports,
              color: const Color(0xFFE83E8C),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MiniGameScreen())),
            ),
            
            // 3. MENU RIWAYAT KONSUMSI OBAT
            _buildMenuCard(
              context,
              title: 'Riwayat\nKonsumsi Obat',
              icon: Icons.receipt_long,
              color: const Color(0xFF8B5CF6),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Halaman Riwayat sedang disambungin backend sama Irham...'),
                    backgroundColor: Colors.teal,
                  ),
                );
              },
            ),
            
            // 4. MENU ANALITIK KEPATUHAN
            _buildMenuCard(
              context,
              title: 'Analitik\nKepatuhan',
              icon: Icons.analytics,
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
            ),
            
            // 5. MENU TIPS KESEHATAN
            _buildMenuCard(
              context,
              title: 'Tips\nKesehatan',
              icon: Icons.article,
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HealthArticlesScreen())),
            ),
            
            // 6. MENU PETA APOTEK
            _buildMenuCard(
              context,
              title: 'Peta\nApotek',
              icon: Icons.local_pharmacy,
              color: const Color(0xFF0D9488),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Bantuan buat bikin Kartu Menu biar rapi
  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}