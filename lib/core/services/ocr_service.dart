import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Service untuk OCR (Optical Character Recognition) menggunakan Google ML Kit
/// 
/// Fitur:
/// - Scan text dari kamera
/// - Scan text dari galeri
/// - Extract data terstruktur (nama obat, dosis, frekuensi)
class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();
  
  /// Scan text dari kamera
  Future<String?> scanFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (photo == null) return null;
      
      return await _processImage(photo.path);
    } catch (e) {
      print('❌ Error scanning from camera: $e');
      rethrow;
    }
  }
  
  /// Scan text dari galeri
  Future<String?> scanFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image == null) return null;
      
      return await _processImage(image.path);
    } catch (e) {
      print('❌ Error scanning from gallery: $e');
      rethrow;
    }
  }
  
  /// Process image dan extract text menggunakan ML Kit
  Future<String> _processImage(String imagePath) async {
    try {
      final InputImage inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText result = await _textRecognizer.processImage(inputImage);
      
      print('✅ OCR completed: ${result.text.length} characters extracted');
      
      // Clean up text
      return _cleanText(result.text);
    } catch (e) {
      print('❌ Error processing image: $e');
      rethrow;
    }
  }
  
  /// Clean OCR output (remove extra whitespace, blank lines)
  String _cleanText(String rawText) {
    return rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }
  
  /// Extract data terstruktur dari text hasil OCR
  /// 
  /// Returns:
  /// - raw_text: Text mentah hasil OCR
  /// - medication_name: Nama obat (baris pertama)
  /// - dosage: Dosis obat (contoh: "500mg", "2 tablet")
  /// - frequency: Frekuensi minum (contoh: "3x sehari")
  Map<String, dynamic> extractMedicationData(String text) {
    return {
      'raw_text': text,
      'medication_name': _extractMedicationName(text),
      'dosage': _extractDosage(text),
      'frequency': _extractFrequency(text),
    };
  }
  
  /// Extract nama obat dengan strategi multi-pattern
  /// 
  /// Strategi:
  /// 1. Cari text yang ALL CAPS dan panjang (biasanya nama obat)
  /// 2. Cari pattern nama obat umum (akhiran -cillin, -zole, -prazole, dll)
  /// 3. Filter out kata-kata umum (PT, Indonesia, Farmasi, dll)
  /// 4. Fallback: ambil baris terpanjang yang bukan alamat
  String? _extractMedicationName(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return null;
    
    // Daftar kata yang BUKAN nama obat (filter out)
    final blacklist = [
      'pt', 'indonesia', 'farmasi', 'industri', 'apotek', 'pharmacy',
      'harus', 'dengan', 'resep', 'dokter', 'medical', 'prescription',
      'only', 'tablet', 'kapsul', 'kaplet', 'sirup', 'syrup',
      'no', 'reg', 'gkl', 'dpk', 'bpom', 'halal', 'mui',
      'exp', 'mfg', 'batch', 'lot', 'produksi', 'oleh',
      'jl', 'jalan', 'street', 'kota', 'kabupaten', 'provinsi',
    ];
    
    // Strategi 1: Cari text ALL CAPS yang panjang (>5 karakter) dan bukan blacklist
    for (var line in lines) {
      final words = line.split(' ');
      for (var word in words) {
        final cleaned = word.replaceAll(RegExp(r'[^A-Z]'), '');
        if (cleaned.length >= 5 && 
            cleaned == word.toUpperCase() &&
            !blacklist.any((b) => cleaned.toLowerCase().contains(b))) {
          // Cek apakah ini nama obat yang valid (mengandung huruf saja, minimal 5 karakter)
          if (RegExp(r'^[A-Z]{5,}$').hasMatch(cleaned)) {
            print('✅ Found drug name (ALL CAPS): $cleaned');
            return cleaned;
          }
        }
      }
    }
    
    // Strategi 2: Cari pattern nama obat umum
    final drugPatterns = [
      RegExp(r'\b\w+cillin\b', caseSensitive: false),      // Amoxicillin, Penicillin
      RegExp(r'\b\w+zole\b', caseSensitive: false),        // Omeprazole, Metronidazole
      RegExp(r'\b\w+prazole\b', caseSensitive: false),     // Lansoprazole
      RegExp(r'\b\w+mycin\b', caseSensitive: false),       // Erythromycin
      RegExp(r'\b\w+cycline\b', caseSensitive: false),     // Tetracycline
      RegExp(r'\b\w+olone\b', caseSensitive: false),       // Prednisolone, Methylprednisolone
      RegExp(r'\b\w+pril\b', caseSensitive: false),        // Captopril, Enalapril
      RegExp(r'\b\w+sartan\b', caseSensitive: false),      // Losartan, Valsartan
      RegExp(r'\b\w+statin\b', caseSensitive: false),      // Simvastatin, Atorvastatin
      RegExp(r'\b\w+dipine\b', caseSensitive: false),      // Amlodipine, Nifedipine
    ];
    
    for (var line in lines) {
      for (var pattern in drugPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final drugName = match.group(0)!;
          print('✅ Found drug name (pattern match): $drugName');
          return drugName;
        }
      }
    }
    
    // Strategi 3: Ambil baris terpanjang yang bukan blacklist dan bukan alamat
    String? longestLine;
    int maxLength = 0;
    
    for (var line in lines) {
      // Skip jika mengandung kata blacklist
      if (blacklist.any((b) => line.toLowerCase().contains(b))) continue;
      
      // Skip jika mengandung angka banyak (kemungkinan nomor registrasi/alamat)
      if (RegExp(r'\d{3,}').hasMatch(line)) continue;
      
      // Skip jika terlalu pendek
      if (line.length < 5) continue;
      
      if (line.length > maxLength) {
        maxLength = line.length;
        longestLine = line;
      }
    }
    
    if (longestLine != null) {
      print('✅ Found drug name (longest line): $longestLine');
      return longestLine;
    }
    
    // Fallback: ambil baris pertama yang tidak kosong
    print('⚠️ Using fallback: first non-empty line');
    return lines.first;
  }
  
  /// Extract dosis dari text
  /// 
  /// Pattern yang dicari:
  /// - "500mg", "250 mg"
  /// - "2 tablet", "1 kapsul"
  /// - "10ml", "5 ml"
  String? _extractDosage(String text) {
    // Pattern untuk dosis dengan satuan
    final patterns = [
      RegExp(r'\d+\s?(mg|ml|mcg|g)', caseSensitive: false),
      RegExp(r'\d+\s?(tablet|kapsul|kaplet)', caseSensitive: false),
      RegExp(r'\d+\s?(sendok|tetes)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0);
      }
    }
    
    return null;
  }
  
  /// Extract frekuensi minum dari text
  /// 
  /// Pattern yang dicari:
  /// - "3x sehari", "2 kali sehari"
  /// - "setiap 8 jam", "tiap 6 jam"
  /// - "1x1", "2x1"
  String? _extractFrequency(String text) {
    final patterns = [
      RegExp(r'\d+\s?x\s?(sehari|per hari|perhari)', caseSensitive: false),
      RegExp(r'\d+\s?kali\s?(sehari|per hari|perhari)', caseSensitive: false),
      RegExp(r'(setiap|tiap)\s?\d+\s?jam', caseSensitive: false),
      RegExp(r'\d+x\d+', caseSensitive: false), // Pattern "1x1", "2x1"
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0);
      }
    }
    
    return null;
  }
  
  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
