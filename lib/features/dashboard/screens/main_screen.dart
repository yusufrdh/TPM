import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/api_service.dart';
import '../../profile/screens/profile_screen.dart';
import 'home_screen.dart';
import '../../utilities/screens/tools_menu_screen.dart';
import '../../scanner_ai/screens/ai_assistant_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _currentTimezone = 'WIB';
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getFormattedTime() {
    DateTime displayTime = _now.toUtc().add(const Duration(hours: 7)); 
    if (_currentTimezone == 'WITA') displayTime = _now.toUtc().add(const Duration(hours: 8));
    else if (_currentTimezone == 'WIT') displayTime = _now.toUtc().add(const Duration(hours: 9));
    else if (_currentTimezone == 'London') displayTime = _now.toUtc().add(const Duration(hours: 1));
    return DateFormat('HH:mm:ss').format(displayTime);
  }

  // --- TAB SCANNER DIHAPUS, TERSISA 4 TAB ---
  final List<Widget> _screens = [
    const HomeScreen(),
    const AIAssistantScreen(),
    const ToolsMenuScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.appName, style: TextStyle(fontSize: 18)),
            Text(
              '${_getFormattedTime()} $_currentTimezone',
              style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) => setState(() => _currentTimezone = val),
            itemBuilder: (context) => ['WIB', 'WITA', 'WIT', 'London'].map((String choice) {
              return PopupMenuItem(value: choice, child: Text(choice));
            }).toList(),
            icon: const Icon(Icons.language),
          ),
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () async {
              await ApiService().logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/auth');
            }
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'AI Chat'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Utilitas'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}