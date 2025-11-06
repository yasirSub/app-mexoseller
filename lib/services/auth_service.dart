// ignore_for_file: unused_import

import 'dart:convert';
import 'api_service.dart';
import 'token_storage.dart';
import '../constants/endpoints.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final resp = await ApiService.post(Endpoints.sellerLogin, {
        'email': email,
        'password': password,
      });

      Map<String, dynamic> body;
      try {
        body = json.decode(resp.body) as Map<String, dynamic>;
      } catch (e) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (resp.statusCode == 200 && body['success'] == true) {
        final token = body['data']?['token'] as String?;
        if (token != null) {
          await TokenStorage.writeToken(token);
        }
        return body;
      }

      // Backend returned an error response
      return {
        'success': false,
        'message': (body['message'] ?? 'Login failed').toString(),
      };
    } catch (e) {
      // Network or unexpected error
      return {
        'success': false,
        'message':
            'Could not connect to server (${ApiService.baseUrl}).\n${e.toString()}',
      };
    }
  }

  static Future<void> logout() async {
    try {
      await ApiService.post(Endpoints.sellerLogout, {});
    } catch (e) {
      // Continue with local logout even if API call fails
    }
    await TokenStorage.deleteToken();
  }

  static Future<String?> getToken() async {
    return await TokenStorage.readToken();
  }

  static Future<void> saveToken(String token) async {
    await TokenStorage.writeToken(token);
  }
}
