import 'package:flutter/material.dart';
import '../../../core/services/session_manager.dart';
import '../../../core/services/shake_detector.dart';
import '../../../data/local/database_helper.dart';

class MedicationDetailScreen extends StatefulWidget {
  final int scheduleId;

  const MedicationDetailScreen({
    super.key,
    required this.scheduleId,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  final _dbHelper = DatabaseHelper();
  final _session = SessionManager();
  
  Map<String, dynamic>? _schedule;
  List<Map<String, dynamic>> _todayLogs = [];
  bool _isLoading = true;
  bool _isConfirming = false;
  bool _alreadyTakenToday = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  // ══════════════════════════════════════════════════════════════
  // LOAD DATA
  // ══════════════════════════════════════════════════════════════
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load schedule detail
      final schedule = await _dbHelper.getScheduleById(widget.scheduleId);
      
      if (schedule == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jadwal tidak ditemukan'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      // Load today's intake logs
      final logs = await _dbHelper.getTodayIntakeLogs(widget.scheduleId);
      
      // Check if already taken today (for 1x daily schedule)
      final frequencyType = schedule['frequency_type'] as String;
      final frequencyValue = schedule['frequency_value'] as int;
      final isDailyOnce = frequencyType == 'daily' && frequencyValue == 1;
      final alreadyTaken = isDailyOnce && logs.isNotEmpty;
      
      setState(() {
        _schedule = schedule;
        _todayLogs = logs;
        _alreadyTakenToday = alreadyTaken;
        _isLoading = false;
      });
      
      print('✅ Loaded schedule: ${schedule['med_name']}');
      print('✅ Today logs: ${logs.length}');
      print('✅ Already taken today: $alreadyTaken');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }
  
  // ══════════════════════════════════════════════════════════════
  // CONFIRM MEDICATION TAKEN
  // ══════════════════════════════════════════════════════════════
  
  Future<void> _confirmTaken() async {
    if (_schedule == null || _isConfirming) return;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF0D9488)),
            SizedBox(width: 10),
            Text('Konfirmasi'),
          ],
        ),
        content: Text(
          'Apakah Anda sudah minum ${_schedule!['med_name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('BELUM'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
            ),
            child: const Text('SUDAH'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    // Stop shake detector (user confirmed, no more snooze needed)
    print('🔔 Stopping shake detector for schedule ${widget.scheduleId}');
    ShakeDetector().stopListening();
    
    setState(() => _isConfirming = true);
    
    try {
      final medId = _schedule!['med_id'] as int;
      final dosage = _schedule!['dosage'] as double;
      final totalStock = _schedule!['total_stock'] as double;
      
      print('🔍 DEBUG: medId=$medId, dosage=$dosage, totalStock=$totalStock');
      
      // Confirm medication taken
      final result = await _dbHelper.confirmMedicationTaken(
        scheduleId: widget.scheduleId,
        medId: medId,
        dosage: dosage,
      );
      
      if (mounted) {
        if (result['success']) {
          final newStock = totalStock - dosage;
          
          // Check if stock is now 0 or less
          if (newStock <= 0) {
            // Stock habis, schedule expired (medication TIDAK dihapus)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ ${_schedule!['med_name']} sudah diminum. Stok habis, jadwal dinonaktifkan.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            // Navigate back
            Navigator.pop(context, true);
          } else {
            // Stock masih ada
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ ${_schedule!['med_name']} sudah diminum. Sisa stok: ${newStock.toInt()}'),
                backgroundColor: const Color(0xFF0D9488),
              ),
            );
            // Reload data
            _loadData();
          }
        } else {
          // Error message dari database helper
          final errorMsg = result['message'] as String;
          
          // Parse error untuk UI yang lebih friendly
          String displayMsg = errorMsg;
          Color bgColor = Colors.red;
          
          if (errorMsg.contains('maksimal 1 jam sebelum jadwal')) {
            // Terlalu awal
            displayMsg = '⏰ Terlalu awal! Obat hanya bisa diminum maksimal 1 jam sebelum jadwal.';
            bgColor = Colors.orange;
          } else if (errorMsg.contains('Stok tidak cukup')) {
            // Stok tidak cukup
            displayMsg = errorMsg.replaceAll('Exception: ', '');
            displayMsg = '📦 $displayMsg';
            bgColor = Colors.red.shade700;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMsg),
              backgroundColor: bgColor,
              duration: const Duration(seconds: 5),
              action: errorMsg.contains('Stok tidak cukup')
                  ? SnackBarAction(
                      label: 'Tambah Stok',
                      textColor: Colors.white,
                      onPressed: () {
                        // Navigate to add medication screen
                        Navigator.pushNamed(context, '/add-schedule');
                      },
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Gagal mencatat konsumsi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }
  
  // ══════════════════════════════════════════════════════════════
  // BUILD UI
  // ══════════════════════════════════════════════════════════════
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Detail Obat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0D9488),
              ),
            )
          : _schedule == null
              ? const Center(
                  child: Text('Jadwal tidak ditemukan'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      _buildInfoCard(),
                      
                      const SizedBox(height: 20),
                      
                      // Button Sudah Minum
                      _buildConfirmButton(),
                      
                      const SizedBox(height: 30),
                      
                      // Riwayat Hari Ini
                      _buildTodayLogs(),
                    ],
                  ),
                ),
    );
  }
  
  // ══════════════════════════════════════════════════════════════
  // INFO CARD
  // ══════════════════════════════════════════════════════════════
  
  Widget _buildInfoCard() {
    final medName = _schedule!['med_name'] as String;
    final timeIntake = _schedule!['time_intake'] as String;
    final dosage = _schedule!['dosage'] as double;
    final dosageUnit = _schedule!['dosage_unit'] as String;
    final totalStock = _schedule!['total_stock'] as double;
    final notes = _schedule!['notes'] as String?;
    final isLowStock = totalStock < 5;
    final isInsufficientStock = totalStock < dosage; // Stok tidak cukup untuk 1x minum
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isInsufficientStock 
                      ? Colors.red.shade50 
                      : isLowStock 
                          ? Colors.orange.shade50 
                          : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isInsufficientStock 
                      ? Icons.error_outline 
                      : isLowStock 
                          ? Icons.warning_amber_rounded 
                          : Icons.medication,
                  color: isInsufficientStock 
                      ? Colors.red 
                      : isLowStock 
                          ? Colors.orange 
                          : Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  medName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          
          // Warning banner jika stok tidak cukup
          if (isInsufficientStock) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Stok tidak cukup! Dibutuhkan ${dosage.toInt()} $dosageUnit, tersedia ${totalStock.toInt()} $dosageUnit.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 15),
          
          // Detail info
          _buildInfoRow(Icons.access_time, 'Waktu', '$timeIntake WIB'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.medication, 'Dosis', '${dosage.toInt()} $dosageUnit'),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.inventory_2_outlined,
            'Stok',
            '${totalStock.toInt()} $dosageUnit',
            isWarning: isLowStock || isInsufficientStock,
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.note_outlined, 'Catatan', notes),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isWarning = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isWarning ? Colors.orange.shade700 : Colors.grey.shade600,
        ),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
              color: isWarning ? Colors.orange.shade700 : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
  
  // ══════════════════════════════════════════════════════════════
  // CONFIRM BUTTON
  // ══════════════════════════════════════════════════════════════
  
  Widget _buildConfirmButton() {
    final isDisabled = _alreadyTakenToday || _isConfirming;
    
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _confirmTaken,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: _isConfirming
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_alreadyTakenToday ? Icons.check_circle : Icons.check_circle, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _alreadyTakenToday ? 'SUDAH DIMINUM HARI INI' : 'SUDAH MINUM',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  // ══════════════════════════════════════════════════════════════
  // TODAY LOGS
  // ══════════════════════════════════════════════════════════════
  
  Widget _buildTodayLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Hari Ini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_todayLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                'Belum ada riwayat konsumsi hari ini',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...(_todayLogs.map((log) => _buildLogCard(log)).toList()),
      ],
    );
  }
  
  Widget _buildLogCard(Map<String, dynamic> log) {
    final timestamp = DateTime.parse(log['timestamp'] as String);
    final status = log['status'] as String;
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    
    final statusText = status == 'on-time' ? 'Tepat waktu' : status == 'late' ? 'Terlambat' : 'Terlewat';
    final statusColor = status == 'on-time' ? Colors.green : status == 'late' ? Colors.orange : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            timeStr,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '-',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
