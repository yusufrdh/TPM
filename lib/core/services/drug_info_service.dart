import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service untuk mendapatkan informasi obat dari RxNorm dan OpenFDA API
/// 
/// Flow:
/// 1. Search drug di RxNorm untuk validasi & get RxCUI
/// 2. Get drug info dari OpenFDA menggunakan nama obat
/// 3. Return informasi lengkap obat
class DrugInfoService {
  static const String _rxNormBaseUrl = 'https://rxnav.nlm.nih.gov/REST';
  static const String _openFdaBaseUrl = 'https://api.fda.gov/drug';
  
  /// Search drug di RxNorm berdasarkan nama
  /// 
  /// Returns:
  /// - rxcui: RxNorm Concept Unique Identifier
  /// - name: Nama obat yang tervalidasi
  Future<Map<String, dynamic>?> searchDrugRxNorm(String drugName) async {
    try {
      final url = Uri.parse('$_rxNormBaseUrl/drugs.json?name=${Uri.encodeComponent(drugName)}');
      
      print('🔍 Searching RxNorm: $drugName');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if drug found
        if (data['drugGroup']?['conceptGroup'] != null) {
          final conceptGroups = data['drugGroup']['conceptGroup'] as List;
          
          // Find first group with concept properties
          for (var group in conceptGroups) {
            if (group['conceptProperties'] != null) {
              final concepts = group['conceptProperties'] as List;
              if (concepts.isNotEmpty) {
                final firstConcept = concepts.first;
                
                print('✅ RxNorm found: ${firstConcept['name']} (${firstConcept['rxcui']})');
                
                return {
                  'rxcui': firstConcept['rxcui'],
                  'name': firstConcept['name'],
                  'synonym': firstConcept['synonym'],
                };
              }
            }
          }
        }
        
        print('⚠️ Drug not found in RxNorm');
        return null;
      } else {
        print('❌ RxNorm API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error searching RxNorm: $e');
      return null;
    }
  }
  
  /// Get drug information dari OpenFDA
  /// 
  /// Returns informasi lengkap obat:
  /// - generic_name: Nama generik
  /// - brand_name: Nama brand
  /// - purpose: Kegunaan/indikasi
  /// - warnings: Peringatan
  /// - dosage: Dosis
  /// - active_ingredient: Komposisi aktif
  Future<Map<String, dynamic>?> getDrugInfoOpenFDA(String drugName) async {
    try {
      // Search di label endpoint (paling lengkap)
      final url = Uri.parse(
        '$_openFdaBaseUrl/label.json?search=openfda.brand_name:"$drugName"+openfda.generic_name:"$drugName"&limit=1'
      );
      
      print('🔍 Searching OpenFDA: $drugName');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          
          print('✅ OpenFDA found drug info');
          
          return {
            'generic_name': result['openfda']?['generic_name']?.first ?? 'N/A',
            'brand_name': result['openfda']?['brand_name']?.first ?? 'N/A',
            'manufacturer': result['openfda']?['manufacturer_name']?.first ?? 'N/A',
            'purpose': result['purpose']?.first ?? 'N/A',
            'indications_and_usage': result['indications_and_usage']?.first ?? 'N/A',
            'dosage_and_administration': result['dosage_and_administration']?.first ?? 'N/A',
            'warnings': result['warnings']?.first ?? 'N/A',
            'adverse_reactions': result['adverse_reactions']?.first ?? 'N/A',
            'active_ingredient': result['active_ingredient']?.first ?? 'N/A',
            'inactive_ingredient': result['inactive_ingredient']?.first ?? 'N/A',
            'route': result['openfda']?['route']?.join(', ') ?? 'N/A',
          };
        }
        
        print('⚠️ Drug not found in OpenFDA');
        return null;
      } else if (response.statusCode == 404) {
        print('⚠️ Drug not found in OpenFDA (404)');
        return null;
      } else {
        print('❌ OpenFDA API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting OpenFDA info: $e');
      return null;
    }
  }
  
  /// Get comprehensive drug information
  /// 
  /// Combines data from RxNorm and OpenFDA
  Future<Map<String, dynamic>> getCompleteDrugInfo(String drugName) async {
    final result = <String, dynamic>{
      'success': false,
      'drug_name': drugName,
      'rxnorm_data': null,
      'fda_data': null,
      'error': null,
    };
    
    try {
      // 1. Search di RxNorm untuk validasi
      final rxNormData = await searchDrugRxNorm(drugName);
      result['rxnorm_data'] = rxNormData;
      
      // 2. Get detailed info dari OpenFDA
      final fdaData = await getDrugInfoOpenFDA(drugName);
      result['fda_data'] = fdaData;
      
      // 3. Check if we got any data
      if (rxNormData != null || fdaData != null) {
        result['success'] = true;
      } else {
        result['error'] = 'Drug not found in database';
      }
      
      return result;
    } catch (e) {
      result['error'] = 'Error fetching drug information: $e';
      return result;
    }
  }
  
  /// Clean HTML tags dari text (OpenFDA sering return HTML)
  String cleanHtmlText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }
}
