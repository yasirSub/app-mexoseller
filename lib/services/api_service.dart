import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiService {
  // Set to the base URL you provided
  // Keep the '/api' segment because backend routes use /api prefix
  static String baseUrl = 'http://192.168.31.129:8080/api';

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{'Content-Type': 'application/json'};

    // Add Accept header for JSON responses
    h['Accept'] = 'application/json';

    // Attach Bearer token automatically when available
    final token = await TokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }

    if (headers != null) h.addAll(headers);
    return await http.post(uri, headers: h, body: json.encode(body));
  }

  static Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{'Content-Type': 'application/json'};

    // Add Accept header for JSON responses
    h['Accept'] = 'application/json';

    final token = await TokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }

    if (headers != null) h.addAll(headers);
    return await http.get(uri, headers: h);
  }

  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{'Content-Type': 'application/json'};

    // Add Accept header for JSON responses
    h['Accept'] = 'application/json';

    final token = await TokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }

    if (headers != null) h.addAll(headers);
    final resp = await http.put(uri, headers: h, body: json.encode(body));

    if (resp.statusCode == 404 && !baseUrl.contains('/v1')) {
      try {
        final altUri = Uri.parse('$baseUrl/v1$path');
        debugPrint(
          'PUT ${uri.path} returned 404 — retrying ${altUri.toString()}',
        );
        final altResp = await http.put(
          altUri,
          headers: h,
          body: json.encode(body),
        );
        return altResp;
      } catch (_) {
        return resp;
      }
    }

    return resp;
  }

  static Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{'Content-Type': 'application/json'};

    // Add Accept header for JSON responses
    h['Accept'] = 'application/json';

    final token = await TokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }

    if (headers != null) h.addAll(headers);
    final resp = await http.delete(uri, headers: h);

    if (resp.statusCode == 404 && !baseUrl.contains('/v1')) {
      try {
        final altUri = Uri.parse('$baseUrl/v1$path');
        debugPrint(
          'DELETE ${uri.path} returned 404 — retrying ${altUri.toString()}',
        );
        final altResp = await http.delete(altUri, headers: h);
        return altResp;
      } catch (_) {
        return resp;
      }
    }

    return resp;
  }

  // Multipart file upload for images
  static Future<http.Response> uploadImage(
    String path,
    File imageFile, {
    String type = 'product',
    Map<String, String>? additionalFields,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    // Create multipart request
    final request = http.MultipartRequest('POST', uri);

    // Add authorization header
    final token = await TokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add image file
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    // Add type field
    request.fields['type'] = type;

    // Add any additional fields
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return response;
  }
}
