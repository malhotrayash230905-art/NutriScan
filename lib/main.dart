import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/api_service.dart';
import 'models/report_data.dart';
import 'models/food_recommendation.dart';
import 'screens/chat_screen.dart';



enum MetricStatus { low, normal, high }

class HealthMetric {
  final String id;
  final String name;
  final String displayValue;
  final double numericValue;
  final String unit;
  final double minNormal;
  final double maxNormal;
  final IconData icon;

  HealthMetric({
    required this.id,
    required this.name,
    required this.displayValue,
    required this.numericValue,
    required this.unit,
    required this.minNormal,
    required this.maxNormal,
    required this.icon,
  });

  MetricStatus get status {
    if (numericValue < minNormal) return MetricStatus.low;
    if (numericValue > maxNormal) return MetricStatus.high;
    return MetricStatus.normal;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'displayValue': displayValue,
    'numericValue': numericValue,
    'unit': unit,
    'minNormal': minNormal,
    'maxNormal': maxNormal,
    'iconCodePoint': icon.codePoint,
  };

  factory HealthMetric.fromJson(Map<String, dynamic> json) => HealthMetric(
    id: json['id'],
    name: json['name'],
    displayValue: json['displayValue'],
    numericValue: json['numericValue'],
    unit: json['unit'],
    minNormal: json['minNormal'],
    maxNormal: json['maxNormal'],
    icon: IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'),
  );
}

class AppSettings extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  String language = 'English';
  bool isVegetarian = false;
  double height = 180.0;
  double weight = 75.0;
  int age = 28;
  String gender = 'Male';
  bool? hasAllergy;
  String allergyType = '';
  bool hasReportUploaded = false;

  List<HealthMetric> dashboardMetrics = [
    HealthMetric(id: 'hydration', name: 'Hydration', displayValue: '2.4', numericValue: 2.4, unit: 'L', minNormal: 2.0, maxNormal: 3.5, icon: Icons.water_drop),
    HealthMetric(id: 'calories', name: 'Calories', displayValue: '1850', numericValue: 1850.0, unit: 'kcal', minNormal: 1500, maxNormal: 2500, icon: Icons.local_fire_department),
    HealthMetric(id: 'health_score', name: 'Health Score', displayValue: '88', numericValue: 88.0, unit: '/100', minNormal: 70, maxNormal: 100, icon: Icons.monitor_heart),
    HealthMetric(id: 'sleep', name: 'Sleep', displayValue: '7.5', numericValue: 7.5, unit: 'hrs', minNormal: 7.0, maxNormal: 9.0, icon: Icons.nights_stay),
    HealthMetric(id: 'heart_rate', name: 'Heart Rate', displayValue: '72', numericValue: 72.0, unit: 'bpm', minNormal: 60, maxNormal: 100, icon: Icons.favorite),
    HealthMetric(id: 'blood_pressure', name: 'Blood Pressure', displayValue: '120/80', numericValue: 120.0, unit: 'mmHg', minNormal: 90, maxNormal: 120, icon: Icons.speed),
    HealthMetric(id: 'vitamin_d', name: 'Vitamin D', displayValue: '35', numericValue: 35.0, unit: 'ng/mL', minNormal: 30, maxNormal: 50, icon: Icons.wb_sunny),
  ];

  List<HealthMetric> labMetrics = [
    HealthMetric(id: 'fasting_blood_sugar', name: 'Fasting Blood Sugar', displayValue: '0', numericValue: 0.0, unit: 'mg/dL', minNormal: 70, maxNormal: 99, icon: Icons.healing),
    HealthMetric(id: 'total_cholesterol', name: 'Total Cholesterol', displayValue: '0', numericValue: 0.0, unit: 'mg/dL', minNormal: 120, maxNormal: 200, icon: Icons.pie_chart),
    HealthMetric(id: 'ldl', name: 'LDL', displayValue: '0', numericValue: 0.0, unit: 'mg/dL', minNormal: 40, maxNormal: 100, icon: Icons.arrow_downward),
    HealthMetric(id: 'hdl', name: 'HDL', displayValue: '0', numericValue: 0.0, unit: 'mg/dL', minNormal: 40, maxNormal: 100, icon: Icons.arrow_upward),
    HealthMetric(id: 'triglycerides', name: 'Triglycerides', displayValue: '0', numericValue: 0.0, unit: 'mg/dL', minNormal: 50, maxNormal: 150, icon: Icons.water_drop),
    HealthMetric(id: 'hemoglobin', name: 'Hemoglobin', displayValue: '0', numericValue: 0.0, unit: 'g/dL', minNormal: 13.5, maxNormal: 17.5, icon: Icons.bloodtype),
    HealthMetric(id: 'vitamin_d', name: 'Vitamin D', displayValue: '0', numericValue: 0.0, unit: 'ng/mL', minNormal: 30, maxNormal: 100, icon: Icons.wb_sunny),
    HealthMetric(id: 'vitamin_b12', name: 'Vitamin B12', displayValue: '0', numericValue: 0.0, unit: 'pg/mL', minNormal: 200, maxNormal: 900, icon: Icons.science),
  ];

  List<Map<String, dynamic>> reportHistory = [];
  ReportData? latestReportData;

  void setNewReportData(ReportData data) async {
    hasReportUploaded = true;
    latestReportData = data;
    
    for (int i = 0; i < labMetrics.length; i++) {
      var m = labMetrics[i];
      var metricData = data.metrics[m.name];
      if (metricData != null) {
        labMetrics[i] = HealthMetric(
          id: m.id, 
          name: m.name, 
          displayValue: (metricData.value ?? 0.0).toString(), 
          numericValue: metricData.value ?? 0.0, 
          unit: m.unit, 
          minNormal: m.minNormal, 
          maxNormal: m.maxNormal, 
          icon: m.icon
        );
      }
    }

    reportHistory.insert(0, {
       'date': DateTime.now().toIso8601String(),
       'metrics': labMetrics.map((m) => m.toJson()).toList(),
       'report_data': data.toJson(),
    });

    await saveState();
    notifyListeners();
  }

  List<HealthMetric> _getDefaultLabMetrics() {
    return [
      HealthMetric(id: 'fasting_blood_sugar', name: 'Fasting Blood Sugar', displayValue: '0', numericValue: 0.0, unit: 'mg/dL', minNormal: 70, maxNormal: 99, icon: Icons.healing),
      HealthMetric(id: 'total_cholesterol', name: 'Total Cholesterol', displayValue: '0', numericValue: 0.0, unit: 'mg/dL', minNormal: 120, maxNormal: 200, icon: Icons.pie_chart),
      HealthMetric(id: 'ldl', name: 'LDL', displayValue: '0', numericValue: 0.0, unit: 'mg/dL', minNormal: 40, maxNormal: 100, icon: Icons.arrow_downward),
      HealthMetric(id: 'hdl', name: 'HDL', displayValue: '0', numericValue: 0.0, unit: 'mg/dL', minNormal: 40, maxNormal: 100, icon: Icons.arrow_upward),
      HealthMetric(id: 'triglycerides', name: 'Triglycerides', displayValue: '0', numericValue: 0.0, unit: 'mg/dL', minNormal: 50, maxNormal: 150, icon: Icons.water_drop),
      HealthMetric(id: 'hemoglobin', name: 'Hemoglobin', displayValue: '0', numericValue: 0.0, unit: 'g/dL', minNormal: 13.5, maxNormal: 17.5, icon: Icons.bloodtype),
      HealthMetric(id: 'vitamin_d', name: 'Vitamin D', displayValue: '0', numericValue: 0.0, unit: 'ng/mL', minNormal: 30, maxNormal: 100, icon: Icons.wb_sunny),
      HealthMetric(id: 'vitamin_b12', name: 'Vitamin B12', displayValue: '0', numericValue: 0.0, unit: 'pg/mL', minNormal: 200, maxNormal: 900, icon: Icons.science),
    ];
  }

  String _getUserPrefix() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return userId != null ? '${userId}_' : 'default_';
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = _getUserPrefix();
    await prefs.setBool('${prefix}hasReportUploaded', hasReportUploaded);
    await prefs.setString('${prefix}labMetrics', jsonEncode(labMetrics.map((m) => m.toJson()).toList()));
    await prefs.setString('${prefix}reportHistory', jsonEncode(reportHistory));
    if (latestReportData != null) {
      await prefs.setString('${prefix}latestReportData', jsonEncode(latestReportData!.toJson()));
    } else {
      await prefs.remove('${prefix}latestReportData');
    }
    await prefs.setInt('${prefix}age', age);
    await prefs.setString('${prefix}gender', gender);
  }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = _getUserPrefix();
    
    // Reset state first
    hasReportUploaded = false;
    labMetrics = _getDefaultLabMetrics();
    reportHistory = [];
    latestReportData = null;
    
    hasReportUploaded = prefs.getBool('${prefix}hasReportUploaded') ?? false;
    age = prefs.getInt('${prefix}age') ?? 28;
    gender = prefs.getString('${prefix}gender') ?? 'Male';
    
    if (prefs.containsKey('${prefix}labMetrics')) {
      List<dynamic> list = jsonDecode(prefs.getString('${prefix}labMetrics')!);
      var loadedMetrics = list.map((e) => HealthMetric.fromJson(e)).toList();
      if (loadedMetrics.any((m) => m.name == 'Fasting Blood Sugar')) {
        labMetrics = loadedMetrics;
      }
    }
    if (prefs.containsKey('${prefix}reportHistory')) {
      List<dynamic> hist = jsonDecode(prefs.getString('${prefix}reportHistory')!);
      reportHistory = hist.map((e) => e as Map<String, dynamic>).toList();
    }
    if (prefs.containsKey('${prefix}latestReportData')) {
      latestReportData = ReportData.fromJson(jsonDecode(prefs.getString('${prefix}latestReportData')!));
    }
    notifyListeners();
  }

  void clearState() {
    hasReportUploaded = false;
    labMetrics = _getDefaultLabMetrics();
    reportHistory = [];
    latestReportData = null;
    age = 28;
    gender = 'Male';
    notifyListeners();
  }

  double get bmi => weight / ((height / 100) * (height / 100));

  void updateMetrics(double h, double w) {
    height = h;
    weight = w;
    notifyListeners();
  }

  void updatePersonalDetails(int newAge, String newGender) {
    age = newAge;
    gender = newGender;
    notifyListeners();
  }

  void setAllergy(bool has, [String type = '']) {
    hasAllergy = has;
    allergyType = type;
    notifyListeners();
  }

  void resetAllergy() {
    hasAllergy = null;
    allergyType = '';
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLanguage(String lang) {
    language = lang;
    notifyListeners();
  }

  void toggleVegetarian(bool isVeg) {
    isVegetarian = isVeg;
    notifyListeners();
  }
}

extension StringLocalization on String {
  String get tr {
    final lang = appSettings.language;
    if (lang == 'English') return this;
    const Map<String, Map<String, String>> localizedValues = {
      'Spanish': {
        'NutriScan': 'NutriScan',
        'Welcome Back': 'Bienvenido',
        'Enter details to access health dashboard.': 'Ingrese sus datos para acceder al panel.',
        'Email Address': 'Correo electrónico',
        'Password': 'Contraseña',
        'Sign In': 'Iniciar sesión',
        'Home': 'Inicio',
        'Scanner': 'Escáner',
        'Chat': 'Chat',
        'Diet': 'Dieta',
        'Welcome back,': 'Bienvenido de nuevo,',
        'Here is your latest health overview.': 'Aquí está su último resumen de salud.',
        'Hydration': 'Hidratación',
        'Calories': 'Calorías',
        'Health Score': 'Puntuación de salud',
        'Hemoglobin': 'Hemoglobina',
        'Blood Glucose': 'Glucosa en sangre',
        'Vitamin D': 'Vitamina D',
        'Heart Rate': 'Frecuencia cardíaca',
        'Blood Pressure': 'Presión arterial',
        'Cholesterol': 'Colesterol',
        'Sleep': 'Sueño',
        'Snacks': 'Aperitivos',
        'Dinner': 'Cena',
        'Greek Yogurt & Almonds': 'Yogur griego y almendras',
        'High in calcium and protein. Great for afternoon energy.': 'Alto en calcio y proteínas. Ideal para la energía de la tarde.',
        'Grilled Chicken & Asparagus': 'Pollo asado y espárragos',
        'Lean protein and high fiber for optimal recovery before bed.': 'Proteína magra y fibra alta para una recuperación óptima.',
        'Hummus & Carrot Sticks': 'Hummus y palitos de zanahoria',
        'Rich in fiber and plant-based protein for steady energy.': 'Rico en fibra y proteína vegetal para una energía constante.',
        'Tofu & Broccoli Stir-fry': 'Salteado de tofu y brócoli',
        'Packed with iron and lean plant protein for a fulfilling evening meal.': 'Rico en hierro y proteína vegetal magra para una cena saciante.',
        'Account': 'Cuenta',
        'Personal Information': 'Información personal',
        'View your health parameters like BMI, Height, Weight': 'Ver sus parámetros de salud como IMC, altura, peso',
        'Height': 'Estatura',
        'Weight': 'Peso',
        'BMI': 'IMC',
        'Age': 'Edad',
        'Gender': 'Género',
        'Normal': 'Normal',
        'years': 'años',
        'Male': 'Masculino',
        'Upload your latest blood report': 'Sube tu último análisis',
        'Quantity': 'Cantidad',
        'Edit': 'Editar',
        'Save': 'Guardar',
        'Cancel': 'Cancelar',
        'Underweight': 'Bajo peso',
        'Overweight': 'Sobrepeso',
        'Our AI can analyze your new report to adjust your nutrition plan immediately.': 'Nuestra IA analizará tu informe para ajustar tu plan.',
        'Scan Report': 'Escanear',
        'Upload Report': 'Subir informe',
        'Take a Photo (Camera)': 'Tomar foto (Cámara)',
        'Choose from Photo Gallery': 'Elegir de galería',
        'Medical Report Scanner': 'Escáner médico',
        'Upload your lab results for AI analysis.': 'Sube tus resultados para análisis.',
        'Tap to Upload Report': 'Toca para subir',
        'Use Camera or Gallery (Max 5MB)': 'Cámara o Galería (Máx. 5MB)',
        'Analyzing Document...': 'Analizando...',
        'Analysis Complete': 'Análisis completo',
        'Vitamin D Level': 'Nivel de vitamina D',
        'Suboptimal (22 ng/mL)': 'Subóptimo (22 ng/mL)',
        'Recommendation: Increase sunlight exposure and consumption of fortified foods.': 'Recomendación: Aumente la exposición al sol.',
        'Fasting Glucose': 'Glucosa en ayunas',
        'Normal (85 mg/dL)': 'Normal (85 mg/dL)',
        'Recommendation: Maintain current carbohydrate intake.': 'Recomendación: Mantenga sus carbohidratos.',
        'AI Health Assistant': 'Asistente IA',
        'Type a message...': 'Escribe un mensaje...',
        'Typing...': 'Escribiendo...',
        'Your Nutrition Plan': 'Tu plan de nutrición',
        'AI-tailored based on your latest metrics.': 'Adaptado por IA.',
        'Breakfast': 'Desayuno',
        'Avocado Toast & Eggs': 'Tostada de aguacate',
        'Rich in healthy fats and protein to start the day. Recommended due to slightly lower Vitamin D.': 'Rico en grasas saludables y proteínas.',
        'Lunch': 'Almuerzo',
        'Grilled Salmon Bowl': 'Tazón de salmón',
        'High in Omega-3 to help with cardiovascular optimization.': 'Alto en Omega-3 para optimización cardiovascular.',
        'Settings': 'Ajustes',
        'Preferences': 'Preferencias',
        'Dark Mode': 'Modo oscuro',
        'Change application theme': 'Cambiar tema de la aplicación',
        'Vegetarian Food': 'Comida vegetariana',
        'Select if you prefer vegetarian meals': 'Seleccione si prefiere comidas vegetarianas',
        'Quinoa & Roasted Chickpeas Bowl': 'Tazón de quinoa y garbanzos asados',
        'High in plant-based proteins and fiber.': 'Alto en proteínas de origen vegetal y fibra.',
        'Green Smoothie Bowl': 'Tazón de batido verde',
        'High in vitamins C and K from spinach and berries. Excellent for morning energy.': 'Alto en vitaminas C y K por las espinacas y bayas. Excelente para la energía matutina.',
        'Lentil & Sweet Potato Bowl': 'Tazón de lentejas y camote',
        'Rich in complex carbs, fiber, and Vitamin A for sustained energy and immunity.': 'Rico en carbohidratos complejos, fibra y vitamina A para la energía y la inmunidad.',
        'Language': 'Idioma',
        'Log Out': 'Cerrar sesión',
        'Analysis': 'Análisis',
        'Image / file uploaded successfully': 'Imagen / archivo subido con éxito',
        'Low': 'Bajo',
        'High': 'Alto',
        'Update Allergy Preferences': 'Actualizar preferencias de alergia',
      },
      'French': {
        'NutriScan': 'NutriScan',
        'Welcome Back': 'Bon retour',
        'Enter details to access health dashboard.': 'Saisissez vos données pour accéder au tableau.',
        'Email Address': 'Adresse e-mail',
        'Password': 'Mot de passe',
        'Sign In': 'Se connecter',
        'Home': 'Accueil',
        'Scanner': 'Scanner',
        'Chat': 'Chat',
        'Diet': 'Régime',
        'Welcome back,': 'Bon retour,',
        'Here is your latest health overview.': 'Voici votre aperçu de santé.',
        'Hydration': 'Hydratation',
        'Calories': 'Calories',
        'Health Score': 'Score de santé',
        'Hemoglobin': 'Hémoglobine',
        'Blood Glucose': 'Glycémie',
        'Vitamin D': 'Vitamine D',
        'Heart Rate': 'Fréquence cardiaque',
        'Blood Pressure': 'Pression artérielle',
        'Cholesterol': 'Cholestérol',
        'Sleep': 'Sommeil',
        'Snacks': 'Collations',
        'Dinner': 'Dîner',
        'Greek Yogurt & Almonds': 'Yaourt grec et amandes',
        'High in calcium and protein. Great for afternoon energy.': 'Riche en calcium et en protéines. Idéal pour l\'énergie de l\'après-midi.',
        'Grilled Chicken & Asparagus': 'Poulet grillé et asperges',
        'Lean protein and high fiber for optimal recovery before bed.': 'Protéines maigres et riches en fibres pour une récupération optimale.',
        'Hummus & Carrot Sticks': 'Houmous et bâtonnets de carottes',
        'Rich in fiber and plant-based protein for steady energy.': 'Riche en fibres et en protéines végétales.',
        'Tofu & Broccoli Stir-fry': 'Sauté de tofu et brocoli',
        'Packed with iron and lean plant protein for a fulfilling evening meal.': 'Riche en fer et en protéines végétales.',
        'Account': 'Compte',
        'Personal Information': 'Informations personnelles',
        'View your health parameters like BMI, Height, Weight': 'Voir vos paramètres de santé comme l\'IMC, la taille, le poids',
        'Height': 'Taille',
        'Weight': 'Poids',
        'BMI': 'IMC',
        'Age': 'Âge',
        'Gender': 'Genre',
        'Normal': 'Normal',
        'years': 'ans',
        'Male': 'Homme',
        'Upload your latest blood report': 'Téléchargez votre bilan',
        'Quantity': 'Quantité',
        'Edit': 'Éditer',
        'Save': 'Enregistrer',
        'Cancel': 'Annuler',
        'Underweight': 'Insuffisance pondérale',
        'Overweight': 'Surpoids',
        'Our AI can analyze your new report to adjust your nutrition plan immediately.': 'Notre IA analysera votre rapport pour ajuster votre nutrition.',
        'Scan Report': 'Scanner',
        'Upload Report': 'Télécharger le rapport',
        'Take a Photo (Camera)': 'Prendre photo (Caméra)',
        'Choose from Photo Gallery': 'Choisir de galerie',
        'Medical Report Scanner': 'Scanner médical',
        'Upload your lab results for AI analysis.': 'Téléchargez vos résultats pour l\'IA.',
        'Tap to Upload Report': 'Appuyez pour télécharger',
        'Use Camera or Gallery (Max 5MB)': 'Caméra ou Galerie (Max 5Mo)',
        'Analyzing Document...': 'Analyse...',
        'Analysis Complete': 'Analyse terminée',
        'Vitamin D Level': 'Niveau de vitamine D',
        'Suboptimal (22 ng/mL)': 'Sous-optimal (22 ng/mL)',
        'Recommendation: Increase sunlight exposure and consumption of fortified foods.': 'Recommandation: Augmentez l\'exposition au soleil.',
        'Fasting Glucose': 'Glycémie à jeun',
        'Normal (85 mg/dL)': 'Normal (85 mg/dL)',
        'Recommendation: Maintain current carbohydrate intake.': 'Recommandation: Maintenez l\'apport en glucides.',
        'AI Health Assistant': 'Assistant de santé IA',
        'Type a message...': 'Écrivez un message...',
        'Typing...': 'En train d\'écrire...',
        'Your Nutrition Plan': 'Plan nutritionnel',
        'AI-tailored based on your latest metrics.': 'Personnalisé par l\'IA.',
        'Breakfast': 'Petit déjeuner',
        'Avocado Toast & Eggs': 'Toast à l\'avocat',
        'Rich in healthy fats and protein to start the day. Recommended due to slightly lower Vitamin D.': 'Riche en graisses saines et en protéines.',
        'Lunch': 'Déjeuner',
        'Grilled Salmon Bowl': 'Bol de saumon',
        'High in Omega-3 to help with cardiovascular optimization.': 'Riche en oméga-3.',
        'Settings': 'Paramètres',
        'Preferences': 'Préférences',
        'Dark Mode': 'Mode sombre',
        'Change application theme': 'Changer le thème de l\'app',
        'Vegetarian Food': 'Nourriture végétarienne',
        'Select if you prefer vegetarian meals': 'Sélectionnez si vous préférez les repas végétariens',
        'Quinoa & Roasted Chickpeas Bowl': 'Bol de quinoa et pois chiches rôtis',
        'High in plant-based proteins and fiber.': 'Riche en protéines végétales et en fibres.',
        'Green Smoothie Bowl': 'Bol de smoothie vert',
        'High in vitamins C and K from spinach and berries. Excellent for morning energy.': 'Riche en vitamines C et K grâce aux épinards et aux baies.',
        'Lentil & Sweet Potato Bowl': 'Bol de lentilles et patate douce',
        'Rich in complex carbs, fiber, and Vitamin A for sustained energy and immunity.': 'Riche en glucides complexes, fibres et vitamine A.',
        'Language': 'Langue',
        'Log Out': 'Se déconnecter',
        'Analysis': 'Analyse',
        'Image / file uploaded successfully': 'Image / fichier importé avec succès',
        'Low': 'Faible',
        'High': 'Élevé',
        'Update Allergy Preferences': 'Mettre à jour les préférences d\'allergie',
      },
      'German': {
        'NutriAI': 'NutriAI',
        'Welcome Back': 'Willkommen',
        'Enter details to access health dashboard.': 'Details eingeben, um auf Dashboard zuzugreifen.',
        'Email Address': 'E-Mail',
        'Password': 'Passwort',
        'Sign In': 'Anmelden',
        'Home': 'Startseite',
        'Scanner': 'Scanner',
        'Chat': 'Chat',
        'Diet': 'Diät',
        'Welcome back,': 'Willkommen zurück,',
        'Here is your latest health overview.': 'Hier ist Ihre Gesundheitsübersicht.',
        'Hydration': 'Flüssigkeitszufuhr',
        'Calories': 'Kalorien',
        'Health Score': 'Gesundheitswert',
        'Hemoglobin': 'Hämoglobin',
        'Blood Glucose': 'Blutzucker',
        'Vitamin D': 'Vitamin D',
        'Heart Rate': 'Herzfrequenz',
        'Blood Pressure': 'Blutdruck',
        'Cholesterol': 'Cholesterin',
        'Sleep': 'Schlaf',
        'Snacks': 'Snacks',
        'Dinner': 'Abendessen',
        'Greek Yogurt & Almonds': 'Griechischer Joghurt & Mandeln',
        'High in calcium and protein. Great for afternoon energy.': 'Reich an Kalzium und Protein für Energie am Nachmittag.',
        'Grilled Chicken & Asparagus': 'Gegrilltes Hähnchen & Spargel',
        'Lean protein and high fiber for optimal recovery before bed.': 'Mageres Protein und ballaststoffreich für optimale Erholung.',
        'Hummus & Carrot Sticks': 'Hummus & Karottensticks',
        'Rich in fiber and plant-based protein for steady energy.': 'Reich an Ballaststoffen und pflanzlichem Protein.',
        'Tofu & Broccoli Stir-fry': 'Tofu-Brokkoli-Pfanne',
        'Packed with iron and lean plant protein for a fulfilling evening meal.': 'Viel Eisen und pflanzliches Protein für ein sättigendes Abendessen.',
        'Account': 'Konto',
        'Personal Information': 'Persönliche Informationen',
        'View your health parameters like BMI, Height, Weight': 'Ihre Gesundheitsparameter wie BMI, Größe, Gewicht',
        'Height': 'Größe',
        'Weight': 'Gewicht',
        'BMI': 'BMI',
        'Age': 'Alter',
        'Gender': 'Geschlecht',
        'Normal': 'Normal',
        'years': 'Jahre',
        'Male': 'Männlich',
        'Upload your latest blood report': 'Bericht hochladen',
        'Quantity': 'Menge',
        'Edit': 'Bearbeiten',
        'Save': 'Speichern',
        'Cancel': 'Abbrechen',
        'Underweight': 'Untergewicht',
        'Overweight': 'Übergewicht',
        'Our AI can analyze your new report to adjust your nutrition plan immediately.': 'Unsere KI analysiert Ihren Bericht.',
        'Scan Report': 'Scannen',
        'Upload Report': 'Bericht hochladen',
        'Take a Photo (Camera)': 'Foto machen (Kamera)',
        'Choose from Photo Gallery': 'Aus der Galerie wählen',
        'Medical Report Scanner': 'Medizinischer Scanner',
        'Upload your lab results for AI analysis.': 'Laden Sie Ihre Ergebnisse hoch.',
        'Tap to Upload Report': 'Tippen zum Hochladen',
        'Use Camera or Gallery (Max 5MB)': 'Kamera oder Galerie (Max 5MB)',
        'Analyzing Document...': 'Analysiert...',
        'Analysis Complete': 'Analyse abgeschlossen',
        'Vitamin D Level': 'Vitamin D Spiegel',
        'Suboptimal (22 ng/mL)': 'Suboptimal (22 ng/mL)',
        'Recommendation: Increase sunlight exposure and consumption of fortified foods.': 'Empfehlung: Mehr Sonnenlicht konsumieren.',
        'Fasting Glucose': 'Nüchternblutzucker',
        'Normal (85 mg/dL)': 'Normal (85 mg/dL)',
        'Recommendation: Maintain current carbohydrate intake.': 'Empfehlung: Behalten Sie den Kohlenhydratkonsum bei.',
        'AI Health Assistant': 'KI-Gesundheitsassistent',
        'Type a message...': 'Nachricht eingeben...',
        'Typing...': 'Schreibt...',
        'Your Nutrition Plan': 'Ihr Ernährungsplan',
        'AI-tailored based on your latest metrics.': 'KI-angepasst basierend auf Metriken.',
        'Breakfast': 'Frühstück',
        'Avocado Toast & Eggs': 'Avocado Toast & Eier',
        'Rich in healthy fats and protein to start the day. Recommended due to slightly lower Vitamin D.': 'Reich an gesunden Fetten und Proteinen.',
        'Lunch': 'Mittagessen',
        'Grilled Salmon Bowl': 'Gegrillte Lachs-Bowl',
        'High in Omega-3 to help with cardiovascular optimization.': 'Reich an Omega-3.',
        'Settings': 'Einstellungen',
        'Preferences': 'Präferenzen',
        'Dark Mode': 'Dunkelmodus',
        'Change application theme': 'App-Design ändern',
        'Vegetarian Food': 'Vegetarisches Essen',
        'Select if you prefer vegetarian meals': 'Wählen Sie, ob Sie vegetarische Mahlzeiten bevorzugen',
        'Quinoa & Roasted Chickpeas Bowl': 'Quinoa & geröstete Kichererbsen Bowl',
        'High in plant-based proteins and fiber.': 'Reich an pflanzlichen Proteinen und Ballaststoffen.',
        'Green Smoothie Bowl': 'Grüner Smoothie Bowl',
        'High in vitamins C and K from spinach and berries. Excellent for morning energy.': 'Reich an Vitamin C und K aus Spinat und Beeren.',
        'Lentil & Sweet Potato Bowl': 'Linsen-Süßkartoffel-Bowl',
        'Rich in complex carbs, fiber, and Vitamin A for sustained energy and immunity.': 'Reich an komplexen Kohlenhydraten, Ballaststoffen und Vitamin A.',
        'Language': 'Sprache',
        'Log Out': 'Abmelden',
      }
    };
    return localizedValues[lang]?[this] ?? this;
  }
}


final AppSettings appSettings = AppSettings();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://yambsxghiwbfkpmqdlcj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlhbWJzeGdoaXdiZmtwbXFkbGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1OTQyNTEsImV4cCI6MjA5NDE3MDI1MX0.AQ1xO9x5f3m01RjYPeQYkFeZJlN35_GtenRFn_JVw0o',
  );

  await appSettings.loadState();
  
  runApp(const NutriAiApp());
}

class NutriAiApp extends StatelessWidget {
  const NutriAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, child) {
        return MaterialApp(
          title: 'NutriScan',
          debugShowCheckedModeBanner: false,
          themeMode: appSettings.themeMode,
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Very soft, clean off-white
            primaryColor: const Color(0xFF10B981), // Aesthetic Mint Green
            appBarTheme: const AppBarTheme(
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              secondary: Color(0xFF0EA5E9), // Light sky blue accent
            ),
            cardColor: Colors.white,
            textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.black87,
              displayColor: Colors.black87,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF000000), // True black for max contrast
            primaryColor: const Color(0xFFFFD700), // Elegant Gold
            appBarTheme: const AppBarTheme(
              iconTheme: IconThemeData(color: Color(0xFFFFD700)),
              titleTextStyle: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFD700),
              secondary: Color(0xFFD4AF37), // Darker gold accent
            ),
            cardColor: const Color(0xFF1A1A1A),
            textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: const Color(0xFFFFD700), // Headers in gold
            ),
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

// ---- STATE ----
String? globalUserName;
final GlobalKey<ScannerScreenState> scannerKey = GlobalKey<ScannerScreenState>();

// ---- AUTH WRAPPER ----
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}
class _AuthWrapperState extends State<AuthWrapper> {
  bool isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      
      // Load or clear state based on auth changes
      if (session != null) {
        await appSettings.loadState();
      } else {
        appSettings.clearState();
      }

      if (mounted) {
        setState(() {
          isAuthenticated = session != null;
          if (session != null) {
            globalUserName = session.user.userMetadata?['username'] ?? 'User';
          } else {
            globalUserName = null;
          }
        });
      }
    });
  }

  void _checkAuth() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      setState(() {
        isAuthenticated = true;
        globalUserName = session.user.userMetadata?['username'] ?? 'User';
      });
    }
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return isAuthenticated 
      ? AppShell(key: appShellKey, onLogout: _logout) 
      : const LoginScreen();
  }
}

// ---- GLASS PANEL HELPER ----
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const GlassPanel({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFFFFD700).withOpacity(0.3) : Colors.black.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
    );
  }
}

// ---- LOGIN SCREEN ----
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true; // true = Sign In, false = Sign Up
  String? _errorMsg;
  bool _obscurePass = true;

  void _submit() async {
    setState(() => _errorMsg = null);
    
    final email = _emailController.text.trim();
    final password = _passController.text.trim();
    final username = _userController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMsg = 'Email is required.');
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMsg = 'Please enter a valid email address.');
      return;
    }
    
    if (!_isLogin && username.isEmpty) {
      setState(() => _errorMsg = 'Username is required.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMsg = 'Password is required.');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'username': username},
        );
      }
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
         setState(() => _errorMsg = 'Incorrect email or password.');
      } else if (e.message.contains('rate limit')) {
         setState(() => _errorMsg = 'Too many attempts. Please try again later.');
      } else {
         setState(() => _errorMsg = e.message);
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.biotech, size: 64, color: Theme.of(context).primaryColor),
        const SizedBox(height: 16),
        Text('NutriScan'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Sign in to continue.' : 'Create an account.', 
          textAlign: TextAlign.center, 
          style: const TextStyle(color: Colors.grey)
        ),
        const SizedBox(height: 24),
        
        if (_errorMsg != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
          ),
          const SizedBox(height: 16),
        ],

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
             prefixIcon: const Icon(Icons.email, color: Colors.grey),
             hintText: 'Email Address'.tr,
             filled: true,
             fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        
        if (!_isLogin) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _userController,
            decoration: InputDecoration(
               prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
               hintText: 'Username',
               filled: true,
               fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],

        const SizedBox(height: 16),
        TextField(
          controller: _passController,
          obscureText: _obscurePass,
          decoration: InputDecoration(
             prefixIcon: const Icon(Icons.lock, color: Colors.grey),
             hintText: 'Password'.tr,
             filled: true,
             fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
             suffixIcon: IconButton(
               icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
               onPressed: () => setState(() => _obscurePass = !_obscurePass),
             ),
          ),
        ),
        
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _isLoading ? null : _submit,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? 'Sign In' : 'Sign Up', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() { _isLogin = !_isLogin; _errorMsg = null; }), 
          child: Text(_isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In", style: TextStyle(color: Theme.of(context).primaryColor))
        ),
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: GlassPanel(
                  child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _buildBody()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- APP SHELL (BOTTOM NAV) ----
final GlobalKey<_AppShellState> appShellKey = GlobalKey<_AppShellState>();

class AppShell extends StatefulWidget {
  final VoidCallback onLogout;
  const AppShell({super.key, required this.onLogout});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  
  void goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _goToScanner() {
    setState(() => _currentIndex = 1);
    Future.delayed(const Duration(milliseconds: 300), () {
      scannerKey.currentState?.showPickerOptions();
    });
  }

  List<Widget> get _screens => [
    DashboardScreen(onScanPressed: _goToScanner),
    ScannerScreen(key: scannerKey),
    const AnalysisScreen(),
    ChatScreen(reportData: appSettings.latestReportData),
    NutritionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                const Icon(Icons.biotech, color: Color(0xFF00F2FE)),
                const SizedBox(width: 8),
                Text('NutriAI'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(onLogout: widget.onLogout)));
                },
              )
            ],
          ),
          body: SafeArea(
            child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: IndexedStack(
                 index: _currentIndex,
                 children: _screens,
               ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF141928) : Colors.white,
            selectedItemColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF00F2FE) : const Color(0xFF00B4DB),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: 'Home'.tr),
              BottomNavigationBarItem(icon: const Icon(Icons.document_scanner), label: 'Scanner'.tr),
              BottomNavigationBarItem(icon: const Icon(Icons.analytics), label: 'Analysis'.tr),
              BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble), label: 'Chat'.tr),
              BottomNavigationBarItem(icon: const Icon(Icons.restaurant_menu), label: 'Diet'.tr),
            ],
          ),
        );
      },
    );
  }
}

// ---- DASHBOARD SCREEN ----
class DashboardScreen extends StatefulWidget {
  final VoidCallback onScanPressed;
  const DashboardScreen({super.key, required this.onScanPressed});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _waterGlasses = 0;
  String? _selectedMood;
  bool _isFasting = false;
  DateTime? _fastStartTime;
  Timer? _fastTimer;

  final List<String> _healthTips = [
    "Drinking water before meals can reduce calorie intake by 13%.",
    "A 15-minute walk after meals helps regulate blood sugar.",
    "Sleep is just as important as nutrition and exercise.",
    "Vitamin D from morning sunlight improves mood and immunity.",
    "Eating protein at breakfast reduces cravings throughout the day.",
  ];

  @override
  void initState() {
    super.initState();
    if (_isFasting) {
      _startTimer();
    }
  }

  void _startTimer() {
    _fastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fastTimer?.cancel();
    super.dispose();
  }

  String _getFastDuration() {
    if (_fastStartTime == null) return "00:00:00";
    final diff = DateTime.now().difference(_fastStartTime!);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(diff.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(diff.inSeconds.remainder(60));
    return "${twoDigits(diff.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    String tipOfTheDay = _healthTips[DateTime.now().day % _healthTips.length];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF00F2FE),
              child: Text(globalUserName?[0].toUpperCase() ?? 'U', style: const TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(globalUserName ?? 'User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24, thickness: 1),
        const SizedBox(height: 16),
        
        // WATER TRACKER
        GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daily Hydration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('$_waterGlasses / 8 Glasses', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _waterGlasses / 8,
                        minHeight: 12,
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF00F2FE)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'water_btn',
                mini: true,
                backgroundColor: const Color(0xFF00F2FE),
                onPressed: () {
                  if (_waterGlasses < 8) {
                    setState(() => _waterGlasses++);
                  }
                },
                child: const Icon(Icons.add, color: Colors.black),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // MOOD LOGGER
        GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How are you feeling today?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['😫', '🙁', '😐', '🙂', '🤩'].map((emoji) {
                  bool isSelected = _selectedMood == emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00F2FE).withOpacity(0.2) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? const Color(0xFF00F2FE) : Colors.transparent, width: 2),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // FASTING TIMER
        GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Intermittent Fasting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _isFasting ? 'Fasting for: ${_getFastDuration()}' : 'Ready to start your fast?',
                      style: TextStyle(
                        fontSize: _isFasting ? 22 : 14, 
                        fontWeight: _isFasting ? FontWeight.bold : FontWeight.normal,
                        color: _isFasting ? const Color(0xFF00F2FE) : Colors.grey
                      )
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFasting ? Colors.redAccent : const Color(0xFF00F2FE),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    _isFasting = !_isFasting;
                    if (_isFasting) {
                      _fastStartTime = DateTime.now();
                      _startTimer();
                    } else {
                      _fastTimer?.cancel();
                    }
                  });
                },
                child: Text(_isFasting ? 'End Fast' : 'Start Fast', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // HEALTH TIP
        GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tip of the Day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber)),
                    const SizedBox(height: 4),
                    Text(tipOfTheDay, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ---- SCANNER SCREEN ----
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => ScannerScreenState();
}

class ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _scanning = false;
  bool _scanned = false;
  XFile? _selectedFile;

  void _pickImage(ImageSource source) async {
    if (_scanning) return;
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedFile = image;
        _scanning = true;
      });
      
      try {
        final bytes = await image.readAsBytes();
        final dietType = appSettings.isVegetarian ? 'veg' : 'non-veg';
        final allergies = (appSettings.hasAllergy ?? false) ? appSettings.allergyType : 'None';
        final reportData = await ApiService.analyzeReport(bytes, image.name, dietType, allergies);
        
        appSettings.setNewReportData(reportData);
        
        setState(() {
          _scanning = false;
          _scanned = true;
        });
      } catch (e) {
        setState(() {
          _scanning = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Upload Report'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00F2FE)),
              title: Text('Take a Photo (Camera)'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF00F2FE)),
              title: Text('Choose from Photo Gallery'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medical Report Scanner'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Upload your lab results for AI analysis.'.tr, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  
                  if (!_scanned)
                    GestureDetector(
                      onTap: _scanning ? null : showPickerOptions,
                      child: GlassPanel(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                 _scanning ? Icons.hourglass_bottom : Icons.add_a_photo, 
                                 size: 64, color: const Color(0xFF00F2FE)
                              ),
                              const SizedBox(height: 16),
                              Text(_scanning ? 'Analyzing Document...'.tr : 'Tap to Upload Report'.tr, style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 8),
                              if (!_scanning) Text('Use Camera or Gallery (Max 5MB)'.tr, style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: GlassPanel(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 64, color: Colors.greenAccent),
                              const SizedBox(height: 16),
                              Text('Image / file uploaded successfully'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---- ANALYSIS SCREEN ----
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analysis'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('AI-tailored based on your latest report.'.tr, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Expanded(
              child: !appSettings.hasReportUploaded 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No Report Scanned'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Upload a report from the Scanner tab to view your analysis.'.tr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: appSettings.labMetrics.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final m = appSettings.labMetrics[index];
                    Color color;
                    String statusStr;
                    switch(m.status) {
                      case MetricStatus.low: 
                        color = Colors.amberAccent; 
                        statusStr = 'Low'.tr;
                        break;
                      case MetricStatus.high: 
                        color = Colors.redAccent; 
                        statusStr = 'High'.tr;
                        break;
                      default: 
                        color = Colors.grey; 
                        statusStr = 'Normal'.tr;
                        break;
                    }
                    return GlassPanel(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(m.icon, color: color, size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.name.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      Text('$statusStr (${m.minNormal} - ${m.maxNormal} ${m.unit})', style: TextStyle(color: color, fontSize: 12)),
                                    ]
                                  )
                                )
                              ]
                            )
                          ),
                          const SizedBox(width: 8),
                          Text('${m.displayValue} ${m.unit}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                        ]
                      )
                    );
                  }
                ),
            )
          ]
        );
      }
    );
  }
}

// ---- CHAT SCREEN (Moved to lib/screens/chat_screen.dart) ----

// ---- ALLERGY QUESTIONNAIRE ----
class AllergyQuestionnaire extends StatefulWidget {
  const AllergyQuestionnaire({super.key});

  @override
  State<AllergyQuestionnaire> createState() => _AllergyQuestionnaireState();
}

class _AllergyQuestionnaireState extends State<AllergyQuestionnaire> {
  bool _showInput = false;
  bool _isLoading = false;
  final TextEditingController _tc = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diet Tailoring'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Before we show your recommendations, do you have any food allergies?'.tr, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (!_showInput) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F2FE), padding: const EdgeInsets.all(16)),
                  onPressed: () => setState(() => _showInput = true),
                  child: Text('Yes'.tr, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                )
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00F2FE)), padding: const EdgeInsets.all(16)),
                  onPressed: () => _updateDietAndSave(false, ''),
                  child: Text('No'.tr, style: const TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold)),
                )
              )
            ]
          )
        ] else ...[
          TextField(
            controller: _tc,
            decoration: InputDecoration(
              hintText: 'E.g. Peanuts, Gluten, Dairy...'.tr,
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F2FE), padding: const EdgeInsets.all(16)),
            onPressed: () {
              if (_tc.text.trim().isNotEmpty) {
                 _updateDietAndSave(true, _tc.text.trim());
              } else {
                 _updateDietAndSave(false, '');
              }
            },
            child: Text('Save Preferences'.tr, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showInput = false),
              child: Text('Back'.tr, style: const TextStyle(color: Colors.grey)),
            ),
          )
        ]
      ]
    );
  }

  Future<void> _updateDietAndSave(bool hasAllergy, String type) async {
    if (appSettings.latestReportData == null) {
      appSettings.setAllergy(hasAllergy, type);
      if (Navigator.canPop(context)) Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<String> outOfRange = appSettings.labMetrics
          .where((m) => m.status != 'Normal' && m.status != 'Unknown')
          .map((m) => '${m.name} is ${m.status} (${m.displayValue})')
          .toList();

      String dietType = appSettings.isVegetarian ? 'veg' : 'non-veg';
      
      final newRecommendations = await ApiService.updateDiet(outOfRange, dietType, type);
      
      appSettings.setAllergy(hasAllergy, type);
      
      ReportData currentData = appSettings.latestReportData!;
      ReportData newData = ReportData(metrics: currentData.metrics, recommendations: newRecommendations);
      appSettings.setNewReportData(newData);

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update diet: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }
}

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  bool _isLoading = false;

  Future<void> _toggleVegStatus(bool isVeg) async {
    if (appSettings.latestReportData == null) {
      appSettings.toggleVegetarian(isVeg);
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<String> outOfRange = appSettings.labMetrics
          .where((m) => m.status != 'Normal' && m.status != 'Unknown')
          .map((m) => '${m.name} is ${m.status} (${m.displayValue})')
          .toList();

      String dietType = isVeg ? 'veg' : 'non-veg';
      
      final newRecommendations = await ApiService.updateDiet(outOfRange, dietType, appSettings.allergyType);
      
      appSettings.toggleVegetarian(isVeg);
      
      ReportData currentData = appSettings.latestReportData!;
      ReportData newData = ReportData(metrics: currentData.metrics, recommendations: newRecommendations);
      appSettings.setNewReportData(newData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update diet: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Widget> _getMeals(BuildContext context, bool isVeg) {
    if (!appSettings.hasReportUploaded) {
      return [
         const Center(
           child: Padding(
             padding: EdgeInsets.symmetric(vertical: 40),
             child: Text('Scan a report to unlock your AI nutrition plan.', style: TextStyle(color: Colors.grey)),
           ),
         )
      ];
    }

    if (_isLoading) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        )
      ];
    }

    final rec = appSettings.latestReportData?.recommendations;
    if (rec == null) {
      return [
         const Center(
           child: Padding(
             padding: EdgeInsets.symmetric(vertical: 40),
             child: Text('AI recommendations are missing.', style: TextStyle(color: Colors.grey)),
           ),
         )
      ];
    }

    List<Widget> mealWidgets = [];
    
    void addMeals(String type, List<Meal> meals) {
      if (meals.isEmpty) return;
      mealWidgets.add(Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(type.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00F2FE))),
      ));
      for (var meal in meals) {
        mealWidgets.add(_buildMealCard(context, meal));
        mealWidgets.add(const SizedBox(height: 12));
      }
    }

    addMeals('Breakfast', rec.breakfast);
    addMeals('Lunch', rec.lunch);
    addMeals('Dinner', rec.dinner);

    return mealWidgets;
  }

  Widget _buildMealCard(BuildContext context, Meal meal) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(
          title: meal.name,
          tag: 'Meal',
          desc: meal.reason,
          macros: 'Portion: ${meal.portion}',
          ingredients: const [],
          steps: const [],
        )));
      },
      borderRadius: BorderRadius.circular(16),
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00F2FE).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant, color: Color(0xFF00F2FE)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(meal.reason, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text('Portion: ${meal.portion}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, child) {
        bool isVeg = appSettings.isVegetarian;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Nutrition Plan'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 12,
              children: [
                ToggleButtons(
                  borderRadius: BorderRadius.circular(20),
                  isSelected: [isVeg, !isVeg],
                  onPressed: (index) {
                    if (index == 0 && !isVeg) _toggleVegStatus(true);
                    if (index == 1 && isVeg) _toggleVegStatus(false);
                  },
                  selectedColor: Colors.white,
                  fillColor: isVeg ? Colors.green : Colors.redAccent,
                  color: Colors.grey,
                  constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
                  children: const [
                    Text('Veg', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Non-Veg', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: SingleChildScrollView(child: AllergyQuestionnaire()),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 14),
                  label: Text('Edit Allergies'.tr, style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _getMeals(context, isVeg),
              ),
            )
          ],
        );
      },
    );
  }
}

// ---- SETTINGS SCREEN ----
class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    bool isDark = appSettings.themeMode == ThemeMode.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                GlassPanel(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF00F2FE),
                        child: Text(globalUserName?[0] ?? 'U', style: const TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(globalUserName ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            Text(Supabase.instance.client.auth.currentUser?.email ?? 'unknown@example.com', style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Account'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GlassPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person, color: Color(0xFF00F2FE)),
                        title: Text('Personal Information'.tr),
                        subtitle: Text('View your health parameters like BMI, Height, Weight'.tr),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen()));
                        },
                      ),
                      const Divider(height: 1, color: Colors.grey, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.history, color: Color(0xFF00F2FE)),
                        title: Text('Report History'.tr),
                        subtitle: Text('View previously scanned lab reports'.tr),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportHistoryScreen()));
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text('Preferences'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GlassPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('Dark Mode'.tr),
                        subtitle: Text('Change application theme'.tr),
                        value: isDark,
                        activeColor: const Color(0xFF00F2FE),
                        onChanged: (val) {
                          appSettings.toggleTheme(val);
                          setState((){});
                        },
                      ),
                      const Divider(height: 1, color: Colors.grey, indent: 16, endIndent: 16),
                      ListTile(
                        title: Text('Language'.tr),
                        subtitle: Text(appSettings.language),
                        trailing: DropdownButton<String>(
                          value: appSettings.language,
                          underline: const SizedBox(),
                          items: ['English', 'Spanish', 'French', 'German'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              appSettings.setLanguage(val);
                              setState((){});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                GlassPanel(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: Text('Log Out'.tr, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () {
                      showGeneralDialog(
                        context: context,
                        pageBuilder: (context, anim1, anim2) => const SizedBox(),
                        barrierDismissible: true,
                        barrierColor: Colors.black.withOpacity(0.5),
                        barrierLabel: '',
                        transitionBuilder: (context, anim1, anim2, child) {
                          return Transform.scale(
                            scale: Curves.easeInOut.transform(anim1.value),
                            child: Opacity(
                              opacity: anim1.value,
                              child: AlertDialog(
                                backgroundColor: Theme.of(context).cardColor,
                                titlePadding: const EdgeInsets.only(left: 24, top: 16, right: 8),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Are you sure?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                content: const Text('Do you really want to log out?'),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context); // close dialog
                                      Navigator.pop(context); // close settings
                                      widget.onLogout();
                                    },
                                    child: const Text('Yes, Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 250),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      );
  }
}

// ---- PERSONAL INFO SCREEN ----
class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  void _editMetric(BuildContext context, String title, double currentVal, Function(double) onSave) {
    TextEditingController ctrl = TextEditingController(text: currentVal.toStringAsFixed(1));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Edit'.tr + ' ' + title),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel'.tr)),
        ElevatedButton(onPressed: () {
          double? val = double.tryParse(ctrl.text);
          if (val != null) onSave(val);
          Navigator.pop(ctx);
        }, child: Text('Save'.tr)),
      ]
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        String bmiDesc = appSettings.bmi < 18.5 ? 'Underweight' : appSettings.bmi < 25 ? 'Normal' : 'Overweight';
        return Scaffold(
          appBar: AppBar(
            title: Text('Personal Information'.tr),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    GlassPanel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildEditableRow(context, Icons.height, 'Height'.tr, '${appSettings.height.toStringAsFixed(1)} cm', () {
                            _editMetric(context, 'Height'.tr, appSettings.height, (v) => appSettings.updateMetrics(v, appSettings.weight));
                          }),
                          const Divider(color: Colors.grey, height: 1),
                          _buildEditableRow(context, Icons.monitor_weight, 'Weight'.tr, '${appSettings.weight.toStringAsFixed(1)} kg', () {
                            _editMetric(context, 'Weight'.tr, appSettings.weight, (v) => appSettings.updateMetrics(appSettings.height, v));
                          }),
                          const Divider(color: Colors.grey, height: 1),
                          _buildInfoRow(context, Icons.accessibility_new, 'BMI'.tr, '${appSettings.bmi.toStringAsFixed(1)} (' + bmiDesc.tr + ')'),
                          const Divider(color: Colors.grey, height: 1),
                          _buildEditableRow(context, Icons.cake, 'Age'.tr, '${appSettings.age} ' + 'years'.tr, () {
                            _editMetric(context, 'Age'.tr, appSettings.age.toDouble(), (v) => appSettings.updatePersonalDetails(v.toInt(), appSettings.gender));
                          }),
                          const Divider(color: Colors.grey, height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, color: Color(0xFF00F2FE), size: 28),
                                const SizedBox(width: 16),
                                Text('Gender'.tr, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                                const Spacer(),
                                DropdownButton<String>(
                                  value: appSettings.gender,
                                  underline: const SizedBox(),
                                  dropdownColor: Theme.of(context).cardColor,
                                  items: ['Male', 'Female', 'Others'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      appSettings.updatePersonalDetails(appSettings.age, val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ),
        );
      }
    );
  }

  Widget _buildEditableRow(BuildContext context, IconData icon, String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00F2FE), size: 28),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 16, color: Colors.grey),
          ],
        )
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00F2FE), size: 28),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      )
    );
  }
}

// ---- RECIPE DETAIL SCREEN ----
class RecipeDetailScreen extends StatelessWidget {
  final String title;
  final String tag;
  final String desc;
  final String macros;
  final List<String> ingredients;
  final List<String> steps;

  const RecipeDetailScreen({
    super.key,
    required this.title,
    required this.tag,
    required this.desc,
    required this.macros,
    required this.ingredients,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Details'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Container(
                   height: 200,
                   decoration: BoxDecoration(
                     color: Theme.of(context).brightness == Brightness.dark ? Colors.black45 : Colors.black12,
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Center(child: Icon(Icons.restaurant, size: 80, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.2))),
                ),
                const SizedBox(height: 24),
                Chip(label: Text(tag, style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 12)), backgroundColor: const Color(0xFF00F2FE).withOpacity(0.2), side: BorderSide.none),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 16),
                GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant_menu, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(macros, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ]
                  )
                ),
                const SizedBox(height: 32),
              ],
            )
        ),
    );
  }
}

// ---- REPORT HISTORY SCREEN ----
class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report History'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appSettings,
          builder: (context, _) {
            if (appSettings.reportHistory.isEmpty) {
              return Center(child: Text('No reports scanned yet.'.tr, style: const TextStyle(color: Colors.grey)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appSettings.reportHistory.length,
              itemBuilder: (context, index) {
                final report = appSettings.reportHistory[index];
                final date = DateTime.tryParse(report['date'] ?? '') ?? DateTime.now();
                final metrics = (report['metrics'] as List).map((e) => HealthMetric.fromJson(e)).toList();
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      if (report['report_data'] != null) {
                        appSettings.latestReportData = ReportData.fromJson(report['report_data']);
                        appSettings.labMetrics = metrics;
                        appSettings.saveState();
                        appSettings.notifyListeners();
                        Navigator.pop(context); // close history
                        Navigator.pop(context); // close settings
                        appShellKey.currentState?.goToTab(2); // go to analysis tab
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report details not available.')));
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: GlassPanel(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('Report from: '.tr + '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: Theme.of(context).cardColor,
                                      title: const Text('Delete Report?', style: TextStyle(fontWeight: FontWeight.bold)),
                                      content: const Text('Are you sure you want to completely delete this report and its diet plan?'),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            appSettings.reportHistory.removeAt(index);
                                            if (appSettings.latestReportData != null && report['report_data'] != null) {
                                              if (index == 0 || appSettings.reportHistory.isEmpty) {
                                                appSettings.latestReportData = null;
                                                appSettings.labMetrics = [];
                                              }
                                            }
                                            appSettings.saveState();
                                            appSettings.notifyListeners();
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ]
                          ),
                          const SizedBox(height: 12),
                          ...metrics.take(4).map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(m.icon, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(child: Text(m.name.tr + ': ', style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis)),
                                Text(m.displayValue + ' ' + m.unit, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ]
                            ),
                          )),
                          if (metrics.length > 4) Text('... and ${metrics.length - 4} more'.tr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ]
                      )
                    ),
                  ),
                );
              }
            );
          },
        ),
      ),
    );
  }
}