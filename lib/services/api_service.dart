import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/report_data.dart';
import '../models/food_recommendation.dart';

class ApiService {
  static const String baseUrl = 'http://10.196.221.233:8000/api'; // Replace with deployed URL in production

  static Future<ReportData> analyzeReport(List<int> imageBytes, String filename, String dietType, String allergies) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze-report'));
    request.fields['diet_type'] = dietType;
    request.fields['allergies'] = allergies;
    
    var pic = http.MultipartFile.fromBytes(
      'image', 
      imageBytes, 
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(pic);
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return ReportData.fromJson(json.decode(response.body));
    } else {
      // Decode the error message if possible
      String errorMessage = response.body;
      try {
        final errJson = json.decode(response.body);
        if (errJson['detail'] != null) {
          errorMessage = errJson['detail'];
        }
      } catch (_) {}
      
      if (response.statusCode == 429 || errorMessage.contains('429') || errorMessage.contains('quota')) {
        throw Exception('API Rate Limit Exceeded. Please wait 1 minute before trying again.');
      }
      throw Exception('Server Error: $errorMessage');
    }
  }

  static Future<FoodRecommendation> updateDiet(List<String> outOfRange, String dietType, String allergies) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update-diet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'out_of_range': outOfRange,
        'diet_type': dietType,
        'allergies': allergies,
      }),
    );

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
      throw Exception('Failed to update diet: $errorMessage');
    }
  }
}
