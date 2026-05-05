import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/drug_info_service.dart';

class DrugInfoScreen extends StatefulWidget {
  const DrugInfoScreen({super.key});

  @override
  State<DrugInfoScreen> createState() => _DrugInfoScreenState();
}

class _DrugInfoScreenState extends State<DrugInfoScreen> {
  final OCRService _ocrService = OCRService();
  final DrugInfoService _drugInfoService = DrugInfoService();
  
  String? _extractedDrugName;
  String? _rawOcrText;
  List<String> _detectedWords = [];
  Map<String, dynamic>? _drugInfo;
  bool _isScanning = false;
  bool _isFetchingInfo = false;
  String? _errorMessage;
  bool _showWordSelection = false;
  
  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
  
  Future<void> _scanFromCamera() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _drugInfo = null;
      _showWordSelection = false;
    });
    
    try {
      final text = await _ocrService.scanFromCamera();
      
      if (text != null && text.isNotEmpty) {
        setState(() => _rawOcrText = text);
        
        // Extract all potential drug names
        final words = text.split(RegExp(r'[\s\n]+')).where((w) {
          final cleaned = w.replaceAll(RegExp(r'[^A-Za-z]'), '');
          return cleaned.length >= 4;
        }).toSet().toList();
        
        setState(() => _detectedWords = words);
        
        // Try auto-extract
        final data = _ocrService.extractMedicationData(text);
        final drugName = data['medication_name'] as String?;
        
        if (drugName != null && drugName.isNotEmpty) {
          setState(() => _extractedDrugName = drugName);
          await _fetchDrugInfo(drugName);
        } else {
          // Auto-extract gagal, tampilkan word selection
          setState(() {
            _showWordSelection = true;
            _errorMessage = 'Pilih nama obat dari daftar di bawah';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Tidak ada text yang terdeteksi';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal scan dari kamera: $e';
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }
  
  Future<void> _scanFromGallery() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _drugInfo = null;
      _showWordSelection = false;
    });
    
    try {
      final text = await _ocrService.scanFromGallery();
      
      if (text != null && text.isNotEmpty) {
        setState(() => _rawOcrText = text);
        
        // Extract all potential drug names
        final words = text.split(RegExp(r'[\s\n]+')).where((w) {
          final cleaned = w.replaceAll(RegExp(r'[^A-Za-z]'), '');
          return cleaned.length >= 4;
        }).toSet().toList();
        
        setState(() => _detectedWords = words);
        
        // Try auto-extract
        final data = _ocrService.extractMedicationData(text);
        final drugName = data['medication_name'] as String?;
        
        if (drugName != null && drugName.isNotEmpty) {
          setState(() => _extractedDrugName = drugName);
          await _fetchDrugInfo(drugName);
        } else {
          // Auto-extract gagal, tampilkan word selection
          setState(() {
            _showWordSelection = true;
            _errorMessage = 'Pilih nama obat dari daftar di bawah';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Tidak ada text yang terdeteksi';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal scan dari galeri: $e';
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }
  
  Future<void> _fetchDrugInfo(String drugName) async {
    setState(() {
      _isFetchingInfo = true;
      _errorMessage = null;
      _drugInfo = null;
    });
    
    try {
      final info = await _drugInfoService.getCompleteDrugInfo(drugName);
      
      if (info['success'] == true) {
        setState(() => _drugInfo = info);
      } else {
        setState(() {
          _errorMessage = info['error'] ?? 'Informasi obat tidak ditemukan';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil informasi obat: $e';
      });
    } finally {
      setState(() => _isFetchingInfo = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Informasi Obat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            _buildInstructionsCard(),
            
            const SizedBox(height: 20),
            
            // Scan Buttons
            if (!_isScanning && !_isFetchingInfo) ...[
              _buildScanButton(
                icon: Icons.camera_alt,
                label: 'Foto Obat',
                onPressed: _scanFromCamera,
                isPrimary: true,
              ),
              
              const SizedBox(height: 12),
              
              _buildScanButton(
                icon: Icons.photo_library,
                label: 'Pilih dari Galeri',
                onPressed: _scanFromGallery,
                isPrimary: false,
              ),
            ],
            
            // Processing Indicators
            if (_isScanning) _buildProcessingIndicator('Memproses gambar...'),
            if (_isFetchingInfo) _buildProcessingIndicator('Mengambil informasi obat...'),
            
            const SizedBox(height: 20),
            
            // Word Selection (jika auto-extract gagal)
            if (_showWordSelection && _detectedWords.isNotEmpty) ...[
              _buildWordSelectionCard(),
              const SizedBox(height: 16),
            ],
            
            // Error Message
            if (_errorMessage != null && !_showWordSelection) _buildErrorCard(),
            
            // Drug Info Display
            if (_drugInfo != null) ...[
              _buildDrugInfoCard(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: const Color(0xFF0D9488), size: 24),
              const SizedBox(width: 10),
              const Text(
                'Cara Menggunakan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0D9488),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('Foto label atau kemasan obat'),
          _buildTipItem('Pastikan nama obat terlihat jelas'),
          _buildTipItem('Aplikasi akan menampilkan informasi lengkap'),
          _buildTipItem('Informasi dari database FDA & RxNorm'),
        ],
      ),
    );
  }
  
  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScanButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF0D9488) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF0D9488),
          side: isPrimary ? null : const BorderSide(color: Color(0xFF0D9488), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isPrimary ? 2 : 0,
        ),
      ),
    );
  }
  
  Widget _buildProcessingIndicator(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF0D9488),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWordSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Icon(Icons.touch_app, color: const Color(0xFF0D9488), size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pilih Nama Obat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap pada nama obat yang benar:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _detectedWords.map((word) {
              return InkWell(
                onTap: () async {
                  setState(() {
                    _extractedDrugName = word;
                    _showWordSelection = false;
                    _errorMessage = null;
                  });
                  await _fetchDrugInfo(word);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF0D9488).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    word,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrugInfoCard() {
    final rxNormData = _drugInfo!['rxnorm_data'] as Map<String, dynamic>?;
    final fdaData = _drugInfo!['fda_data'] as Map<String, dynamic>?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drug Name Card (Teal background)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.medication, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _extractedDrugName ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (fdaData?['generic_name'] != null && fdaData!['generic_name'] != 'N/A') ...[
                const SizedBox(height: 12),
                Text(
                  'Generic: ${fdaData['generic_name']}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Section Title
        const Text(
          'Identifikasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // RxCUI Info
        if (rxNormData != null) ...[
          _buildInfoRow(
            icon: Icons.tag,
            label: 'RxCUI',
            value: rxNormData['rxcui'] ?? 'N/A',
          ),
        ],
        
        const SizedBox(height: 20),
        
        // FDA Data Sections
        if (fdaData != null) ...[
          if (fdaData['indications_and_usage'] != 'N/A' || fdaData['purpose'] != 'N/A') ...[
            _buildExpandableSection(
              title: 'Kegunaan',
              content: _drugInfoService.cleanHtmlText(
                fdaData['indications_and_usage'] != 'N/A' 
                    ? fdaData['indications_and_usage'] 
                    : fdaData['purpose']
              ),
              icon: Icons.healing,
            ),
            const SizedBox(height: 12),
          ],
          
          if (fdaData['dosage_and_administration'] != 'N/A') ...[
            _buildExpandableSection(
              title: 'Dosis & Cara Pakai',
              content: _drugInfoService.cleanHtmlText(fdaData['dosage_and_administration']),
              icon: Icons.medication_liquid,
            ),
            const SizedBox(height: 12),
          ],
          
          if (fdaData['warnings'] != 'N/A') ...[
            _buildExpandableSection(
              title: 'Peringatan',
              content: _drugInfoService.cleanHtmlText(fdaData['warnings']),
              icon: Icons.warning,
            ),
            const SizedBox(height: 12),
          ],
          
          if (fdaData['adverse_reactions'] != 'N/A') ...[
            _buildExpandableSection(
              title: 'Efek Samping',
              content: _drugInfoService.cleanHtmlText(fdaData['adverse_reactions']),
              icon: Icons.report_problem,
            ),
            const SizedBox(height: 12),
          ],
        ],
        
        const SizedBox(height: 20),
        
        // Disclaimer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Informasi ini bersumber dari database FDA dan RxNorm. Selalu konsultasikan dengan dokter atau apoteker sebelum menggunakan obat.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0D9488)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpandableSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: const Color(0xFF0D9488), size: 20),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
