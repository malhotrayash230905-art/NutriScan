import 'dart:convert';
import 'dart:io' show Platform, SocketException, HttpException;
import 'dart:async' show TimeoutException;
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/report_data.dart';
import '../models/food_recommendation.dart';

class ApiService {
  // ==========================================
  // CENTRALIZED API CONFIGURATION
  // ==========================================
  
  // 1. Local Development Host (used in Debug Mode)
  // For USB connected mode, use '127.0.0.1' (with adb reverse)
  // For Wi-Fi connected mode, change this to your computer's local LAN IP (e.g. '172.25.243.239')
  static const String _localHost = '127.0.0.1'; 

  // 2. Production Cloud Host (used in Release/Production Mode)
  // Once you deploy the backend to Render or Railway, replace this placeholder with your live URL
  static const String _productionCloudHost = 'your-nutriai-backend.onrender.com';

  static String get baseUrl {
    // Allows overriding via: flutter run --dart-define=BACKEND_IP=xxx
    const envIp = String.fromEnvironment('BACKEND_IP');
    if (envIp.isNotEmpty) {
      return 'http://$envIp:8000/api';
    }

    if (kReleaseMode) {
      // Production: Uses secure HTTPS cloud URL
      return 'https://$_productionCloudHost/api';
    } else {
      // Development: Uses local HTTP server
      return 'http://$_localHost:8000/api';
    }
  }

  static String get _cleanErrorMessage {
    return 'Unable to connect to the NutriAI server. Please make sure the server is running and your phone is connected to the same Wi-Fi network.';
  }

  static Future<ReportData> analyzeReport(List<int> imageBytes, String filename, String dietType, String allergies) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze-report'));
      request.fields['diet_type'] = dietType;
      request.fields['allergies'] = allergies;
      request.headers['Connection'] = 'close';
      
      var pic = http.MultipartFile.fromBytes(
        'image', 
        imageBytes, 
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(pic);
      
      var streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return ReportData.fromJson(json.decode(response.body));
      } else {
        String errorMessage = response.body;
        try {
          final errJson = json.decode(response.body);
          if (errJson['detail'] != null) {
            errorMessage = errJson['detail'];
          }
        } catch (_) {}
        
        if (response.statusCode == 429 || errorMessage.contains('429') || errorMessage.contains('quota')) {
          throw Exception('API Rate Limit Exceeded. Please wait a minute before trying again.');
        }
        throw Exception('Server Error: $errorMessage');
      }
    } on SocketException {
      throw Exception(_cleanErrorMessage);
    } on TimeoutException {
      throw Exception('Connection timed out. Please ensure the backend is running and accessible.');
    } catch (e) {
      if (e.toString().contains('Rate Limit')) {
        rethrow;
      }
      throw Exception('Failed to analyze report: $e');
    }
  }

  static Future<FoodRecommendation> updateDiet(List<String> outOfRange, String dietType, String allergies) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-diet'),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
        body: jsonEncode({
          'out_of_range': outOfRange,
          'diet_type': dietType,
          'allergies': allergies,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FoodRecommendation.fromJson(data['recommendations']);
      } else {
        String errorMessage = response.body;
        try {
          final errJson = jsonDecode(response.body);
          if (errJson['detail'] != null) {
            errorMessage = errJson['detail'];
          }
        } catch (_) {}
        
        if (response.statusCode == 429 || errorMessage.contains('429') || errorMessage.contains('quota')) {
          throw Exception('API Rate Limit Exceeded. Please wait a minute before trying again.');
        }
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception(_cleanErrorMessage);
    } on TimeoutException {
      throw Exception('Connection timed out. Please ensure the backend is running and accessible.');
    } catch (e) {
      if (e.toString().contains('Rate Limit')) {
        rethrow;
      }
      throw Exception('Failed to update diet: $e');
    }
  }

  static Future<String> sendMessage(String message, List<Map<String, dynamic>> history, String contextStr) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
        body: jsonEncode({
          'message': message,
          'history': history,
          'context': contextStr,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      } else {
        String errorMessage = response.body;
        if (response.statusCode == 429 || errorMessage.contains('429') || errorMessage.contains('quota')) {
          throw Exception('API Rate Limit Exceeded. Please wait a minute before trying again.');
        }
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception(_cleanErrorMessage);
    } on TimeoutException {
      throw Exception('Connection timed out. Please ensure the backend is running and accessible.');
    } catch (e) {
      if (e.toString().contains('Rate Limit')) {
        rethrow;
      }
      throw Exception('Chat failed: $e');
    }
  }
}

