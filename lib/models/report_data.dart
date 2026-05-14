import 'food_recommendation.dart';

class ReportData {
  final Map<String, MetricResult> metrics;
  final FoodRecommendation? recommendations;

  ReportData({required this.metrics, this.recommendations});

  factory ReportData.fromJson(Map<String, dynamic> json) {
    Map<String, MetricResult> parsedMetrics = {};
    if (json['metrics'] != null) {
      json['metrics'].forEach((key, value) {
        parsedMetrics[key] = MetricResult.fromJson(value);
      });
    }
    return ReportData(
      metrics: parsedMetrics,
      recommendations: json['recommendations'] != null 
          ? FoodRecommendation.fromJson(json['recommendations']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metrics': metrics.map((k, v) => MapEntry(k, v.toJson())),
      'recommendations': recommendations?.toJson(),
    };
  }
}

class MetricResult {
  final double? value;
  final String status; // Low, Normal, High, Unknown

  MetricResult({this.value, required this.status});

  factory MetricResult.fromJson(Map<String, dynamic> json) {
    return MetricResult(
      value: json['value'] != null ? (json['value'] as num).toDouble() : null,
      status: json['status'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'status': status,
    };
  }
}
