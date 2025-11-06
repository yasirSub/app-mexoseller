import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../constants/endpoints.dart';

class CategoryService {
  static Future<Map<String, dynamic>> getCategories({
    String? parentId,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (parentId != null) {
      queryParams['parent_id'] = parentId;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final url = '${Endpoints.categories}$queryString';
    debugPrint('📦 Fetching categories from: $url');

    try {
      final resp = await ApiService.get(url);
      final raw = resp.body;

      debugPrint('📦 Categories API Status: ${resp.statusCode}');
      debugPrint('📦 Categories API Response: $raw');

      if (raw.trim().isEmpty) {
        debugPrint('⚠️ Empty response from categories API');
        return {
          'success': false,
          'message': 'Empty response from server',
          'data': [],
        };
      }

      try {
        final body = json.decode(raw) as Map<String, dynamic>;

        // Check if response has expected structure
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'] as List<dynamic>;
          debugPrint('✅ Found ${data.length} categories');
          return body;
        } else {
          debugPrint('⚠️ Unexpected response structure: $body');
          return {
            'success': false,
            'message': body['message'] ?? 'Invalid response format',
            'data': [],
          };
        }
      } catch (e) {
        debugPrint('❌ JSON decode error: $e');
        return {
          'success': false,
          'message': 'Invalid server response: $e',
          'error': e.toString(),
          'data': [],
          'raw': raw,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Categories API Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
        'data': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getCategory(String id) async {
    final resp = await ApiService.get('${Endpoints.categories}/$id');
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
