class FoodRecommendation {
  final List<Meal> breakfast;
  final List<Meal> lunch;
  final List<Meal> dinner;

  FoodRecommendation({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  factory FoodRecommendation.fromJson(Map<String, dynamic> json) {
    return FoodRecommendation(
      breakfast: json['breakfast'] != null ? (json['breakfast'] as List).map((i) => Meal.fromJson(i)).toList() : [],
      lunch: json['lunch'] != null ? (json['lunch'] as List).map((i) => Meal.fromJson(i)).toList() : [],
      dinner: json['dinner'] != null ? (json['dinner'] as List).map((i) => Meal.fromJson(i)).toList() : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'breakfast': breakfast.map((e) => e.toJson()).toList(),
      'lunch': lunch.map((e) => e.toJson()).toList(),
      'dinner': dinner.map((e) => e.toJson()).toList(),
    };
  }
}

class Meal {
  final String name;
  final String portion;
  final String reason;

  Meal({required this.name, required this.portion, required this.reason});

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: json['name'] ?? '',
      portion: json['portion'] ?? '',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'portion': portion,
      'reason': reason,
    };
  }
}
