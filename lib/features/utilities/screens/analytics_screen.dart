import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/services/session_manager.dart';
import '../../../data/local/database_helper.dart';

/// Screen untuk menampilkan analitik kepatuhan minum obat
/// 
/// Fitur:
/// - Summary cards (total jadwal, kepatuhan %, streak)
/// - Pie chart (on-time, late, missed)
/// - Riwayat konsumsi obat (intake logs)
/// - Filter periode (7 hari, 30 hari, semua)
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SessionManager _session = SessionManager();

  bool _isLoading = true;
  int _selectedPeriod = 7; // 7, 30, atau 0 (semua)

  // Stats data
  int _totalSchedules = 0;
  int _onTimeCount = 0;
  int _lateCount = 0;
  int _missedCount = 0;
  double _adherencePercentage = 0.0;
  int _currentStreak = 0;

  // Intake logs data
  List<Map<String, dynamic>> _intakeLogs = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final userId = _session.userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Load adherence stats
      final stats = await _dbHelper.getAdherenceStats(userId, days: _selectedPeriod);
      
      _onTimeCount = stats['on-time'] ?? 0;
      _lateCount = stats['late'] ?? 0;
      _missedCount = stats['missed'] ?? 0;
      _totalSchedules = _onTimeCount + _lateCount + _missedCount;

      // Calculate adherence percentage
      if (_totalSchedules > 0) {
        _adherencePercentage = (_onTimeCount / _totalSchedules) * 100;
      } else {
        _adherencePercentage = 0.0;
      }

      // Calculate streak (consecutive on-time days)
      _currentStreak = await _calculateStreak(userId);

      // Load intake logs (riwayat konsumsi)
      _intakeLogs = await _loadIntakeLogs(userId, _selectedPeriod);

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading stats: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Hitung streak (berapa hari berturut-turut on-time)
  Future<int> _calculateStreak(int userId) async {
    final db = await _dbHelper.database;
    
    // Ambil semua intake logs, diurutkan dari yang terbaru
    final logs = await db.rawQuery('''
      SELECT 
        DATE(il.timestamp) as date,
        il.status
      FROM intake_logs il
      JOIN schedules s ON il.schedule_id = s.id
      JOIN medications m ON s.med_id = m.id
      WHERE m.user_id = ?
      ORDER BY il.timestamp DESC
    ''', [userId]);
    
    if (logs.isEmpty) return 0;
    
    int streak = 0;
    String? lastDate;
    
    for (var log in logs) {
      final date = log['date'] as String;
      final status = log['status'] as String;
      
      // Skip jika bukan on-time
      if (status != 'on-time') continue;
      
      // Jika ini hari pertama atau hari berbeda dari sebelumnya
      if (lastDate == null || lastDate != date) {
        // Cek apakah hari ini atau kemarin
        final logDate = DateTime.parse(date);
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        final todayStr = DateTime(today.year, today.month, today.day).toIso8601String().split('T')[0];
        final yesterdayStr = DateTime(yesterday.year, yesterday.month, yesterday.day).toIso8601String().split('T')[0];
        
        if (streak == 0) {
          // Hari pertama harus hari ini atau kemarin
          if (date == todayStr || date == yesterdayStr) {
            streak++;
            lastDate = date;
          } else {
            break; // Streak terputus
          }
        } else {
          // Hari berikutnya harus 1 hari sebelum lastDate
          // lastDate pasti tidak null karena streak > 0
          final lastDateTime = DateTime.parse(lastDate!);
          final expectedDate = lastDateTime.subtract(const Duration(days: 1));
          final expectedDateStr = DateTime(expectedDate.year, expectedDate.month, expectedDate.day).toIso8601String().split('T')[0];
          
          if (date == expectedDateStr) {
            streak++;
            lastDate = date;
          } else {
            break; // Streak terputus
          }
        }
      }
    }
    
    return streak;
  }

  /// Load intake logs (riwayat konsumsi obat)
  Future<List<Map<String, dynamic>>> _loadIntakeLogs(int userId, int days) async {
    final db = await _dbHelper.database;
    
    // Tentukan range tanggal
    final endDate = DateTime.now();
    final startDate = days == 0 
        ? DateTime(2020, 1, 1) // Semua data
        : endDate.subtract(Duration(days: days - 1));
    
    final startDateStr = DateTime(startDate.year, startDate.month, startDate.day).toIso8601String();
    
    // Query untuk mengambil intake logs dengan info obat
    final result = await db.rawQuery('''
      SELECT 
        il.id,
        il.timestamp,
        il.status,
        il.note,
        s.time_intake,
        s.dosage,
        s.dosage_unit,
        m.name as med_name,
        m.drug_type
      FROM intake_logs il
      JOIN schedules s ON il.schedule_id = s.id
      JOIN medications m ON s.med_id = m.id
      WHERE m.user_id = ? 
        AND il.timestamp >= ?
      ORDER BY il.timestamp DESC
      LIMIT 20
    ''', [userId, startDateStr]);
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Analitik Kepatuhan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0D9488),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Filter
                    _buildPeriodFilter(),
                    const SizedBox(height: 20),

                    // Summary Cards
                    _buildSummaryCards(),
                    const SizedBox(height: 25),

                    // Pie Chart Section
                    _buildPieChartSection(),
                    const SizedBox(height: 25),

                    // Intake Logs Section (Riwayat Konsumsi)
                    _buildIntakeLogsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterButton('7 Hari', 7),
          _buildFilterButton('30 Hari', 30),
          _buildFilterButton('Semua', 0),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, int days) {
    final isSelected = _selectedPeriod == days;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = days);
          _loadStats();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Jadwal',
            _totalSchedules.toString(),
            Icons.calendar_today,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Kepatuhan',
            '${_adherencePercentage.toStringAsFixed(0)}%',
            Icons.check_circle,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Streak',
            '$_currentStreak hari',
            Icons.local_fire_department,
            const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Kepatuhan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          
          if (_totalSchedules == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'Belum ada data kepatuhan',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: _onTimeCount.toDouble(),
                      title: '$_onTimeCount',
                      color: const Color(0xFF10B981),
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: _lateCount.toDouble(),
                      title: '$_lateCount',
                      color: const Color(0xFFF59E0B),
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: _missedCount.toDouble(),
                      title: '$_missedCount',
                      color: const Color(0xFFEF4444),
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Tepat Waktu', const Color(0xFF10B981)),
              _buildLegendItem('Terlambat', const Color(0xFFF59E0B)),
              _buildLegendItem('Terlewat', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildIntakeLogsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Konsumsi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 15),
          
          if (_intakeLogs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'Belum ada riwayat konsumsi',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _intakeLogs.length,
              separatorBuilder: (context, index) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final log = _intakeLogs[index];
                return _buildIntakeLogItem(log);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildIntakeLogItem(Map<String, dynamic> log) {
    final timestamp = DateTime.parse(log['timestamp'] as String);
    final status = log['status'] as String;
    final medName = log['med_name'] as String;
    final dosage = log['dosage'] as double;
    final dosageUnit = log['dosage_unit'] as String;
    
    // Status color & icon
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'on-time':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        statusText = 'Tepat Waktu';
        break;
      case 'late':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.access_time;
        statusText = 'Terlambat';
        break;
      case 'missed':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        statusText = 'Terlewat';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = status;
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        const SizedBox(width: 12),
        
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$dosage $dosageUnit',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
