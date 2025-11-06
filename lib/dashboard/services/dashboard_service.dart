import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../constants/endpoints.dart';
import '../models/dashboard_models.dart';

class DashboardService {
  static Future<DashboardStats?> getDashboardStats() async {
    try {
      debugPrint('📊 Fetching dashboard stats...');
      final response = await ApiService.get(Endpoints.dashboardStats);

      debugPrint('📊 Dashboard Response Status: ${response.statusCode}');
      debugPrint('📊 Dashboard Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📊 Parsed JSON successfully');

        // Check if response has the expected structure
        if (data['success'] == true && data['data'] != null) {
          debugPrint('📊 Processing dashboard data...');
          return DashboardStats.fromJson(data['data']);
        } else {
          debugPrint('❌ Invalid response structure: $data');
          return null;
        }
      } else {
        debugPrint('❌ Dashboard API Error: ${response.statusCode}');
        debugPrint('❌ Error Body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Dashboard Service Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<bool> refreshDashboardData() async {
    try {
      final response = await ApiService.get(Endpoints.dashboardStats);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Dashboard Refresh Error: $e');
      return false;
    }
  }
}
