import 'dart:convert';
import '../../../services/api_service.dart';
import '../../../constants/endpoints.dart';

class StoreService {
  static Future<Map<String, dynamic>> getSettings() async {
    final resp = await ApiService.get(Endpoints.sellerStoreSettings);
    final raw = resp.body;
    if (raw.trim().isEmpty) {
      return {
        'success': resp.statusCode >= 200 && resp.statusCode < 300,
        'message': resp.reasonPhrase ?? 'Empty response',
      };
    }
    try {
      final body = json.decode(raw) as Map<String, dynamic>;
      return body;
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid server response',
        'error': e.toString(),
        'raw': raw,
      };
    }
  }

  static Future<Map<String, dynamic>> saveSettings(
    Map<String, dynamic> data,
  ) async {
    final resp = await ApiService.put(Endpoints.sellerStoreSettings, data);
    final raw = resp.body;
    if (raw.trim().isEmpty) {
      return {
        'success': resp.statusCode >= 200 && resp.statusCode < 300,
        'message': resp.reasonPhrase ?? 'Empty response',
      };
    }
    try {
      final body = json.decode(raw) as Map<String, dynamic>;
      return body;
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid server response',
        'error': e.toString(),
        'raw': raw,
      };
    }
  }
}
