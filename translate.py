import sys

def main():
    with open('lib/main.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Add Extension
    extension = '''
  void setLanguage(String lang) {
    language = lang;
    notifyListeners();
  }
}

extension StringLocalization on String {
  String get tr {
    final lang = appSettings.language;
    if (lang == 'English') return this;
    const Map<String, Map<String, String>> localizedValues = {
      'Spanish': {
        'Welcome Back': 'Bienvenido de nuevo',
        'Enter details to access health dashboard.': 'Ingrese sus datos para acceder al panel de salud.',
        'Email Address': 'Correo electrónico',
        'Password': 'Contraseña',
        'Sign In': 'Iniciar sesión',
        'NutriAI': 'NutriAI',
        'Home': 'Inicio',
        'Scanner': 'Escáner',
        'Chat': 'Chat',
        'Diet': 'Dieta',
        'Welcome back, ': 'Bienvenido de nuevo, ',
        'Here is your latest health overview.': 'Aquí está su último resumen de salud.',
        'Hydration': 'Hidratación',
        'Calories': 'Calorías',
        'Health Score': 'Puntuación de salud',
        'Upload your latest blood report': 'Sube tu último análisis de sangre',
        'Our AI can analyze your new report to adjust your nutrition plan immediately.': 'Nuestra IA puede analizar su informe para ajustar su plan.',
        'Scan Report': 'Escanear informe',
        'Upload Report': 'Subir informe',
        'Take a Photo (Camera)': 'Tomar una foto (Cámara)',
        'Choose from Photo Gallery': 'Elegir de la galería',
        'Medical Report Scanner': 'Escáner médico',
        'Upload your lab results for AI analysis.': 'Sube tus resultados para análisis de IA.',
        'Tap to Upload Report': 'Toca para subir informe',
        'Use Camera or Gallery (Max 5MB)': 'Usar cámara o galería (Máx. 5MB)',
        'Analyzing Document...': 'Analizando documento...',
        'Analysis Complete': 'Análisis completo',
        'Vitamin D Level': 'Nivel de vitamina D',
        'Suboptimal (22 ng/mL)': 'Subóptimo (22 ng/mL)',
        'Recommendation: Increase sunlight exposure and consumption of fortified foods.': 'Recomendación: Aumente la exposición al sol.',
        'Fasting Glucose': 'Glucosa en ayunas',
        'Normal (85 mg/dL)': 'Normal (85 mg/dL)',
        'Recommendation: Maintain current carbohydrate intake.': 'Recomendación: Mantenga el consumo actual de carbohidratos.',
        'AI Health Assistant': 'Asistente IA',
        'Type a message...': 'Escribe un mensaje...',
        'Typing...': 'Escribiendo...',
        'Hello ': 'Hola ',
        '! I\\'ve reviewed your latest health metrics. How can I help you today?': '! He revisado sus métricas. ¿Cómo puedo ayudarle?',
        'Your Nutrition Plan': 'Tu plan de nutrición',
        'AI-tailored based on your latest metrics.': 'Adaptado por IA en función de tus métricas.',
        'Breakfast': 'Desayuno',
        'Avocado Toast & Eggs': 'Tostada de aguacate y huevos',
        'Rich in healthy fats and protein to start the day. Recommended due to slightly lower Vitamin D.': 'Rico en grasas saludables y proteínas.',
        'Lunch': 'Almuerzo',
        'Grilled Salmon Bowl': 'Tazón de salmón a la parrilla',
        'High in Omega-3 to help with cardiovascular optimization.': 'Alto en Omega-3 para ayudar con la optimización cardiovascular.',
        'Settings': 'Ajustes',
        'Preferences': 'Preferencias',
        'Dark Mode': 'Modo oscuro',
        'Change application theme': 'Cambiar tema de la aplicación',
        'Language': 'Idioma',
        'Log Out': 'Cerrar sesión',
      },
      'French': {
        'Welcome Back': 'Bon retour',
        'Enter details to access health dashboard.': 'Saisissez vos données pour accéder au tableau.',
        'Email Address': 'Adresse e-mail',
        'Password': 'Mot de passe',
        'Sign In': 'Se connecter',
        'NutriAI': 'NutriAI',
        'Home': 'Accueil',
        'Scanner': 'Scanner',
        'Chat': 'Chat',
        'Diet': 'Régime',
        'Welcome back, ': 'Bon retour, ',
        'Here is your latest health overview.': 'Voici votre dernier aperçu de santé.',
        'Hydration': 'Hydratation',
        'Calories': 'Calories',
        'Health Score': 'Score de santé',
        'Upload your latest blood report': 'Téléchargez votre dernier bilan sanguin',
        'Our AI can analyze your new report to adjust your nutrition plan immediately.': 'Notre IA peut analyser votre rapport pour ajuster instantanément votre nutrition.',
        'Scan Report': 'Scanner le rapport',
        'Upload Report': 'Télécharger le rapport',
        'Take a Photo (Camera)': 'Prendre une photo (Caméra)',
        'Choose from Photo Gallery': 'Choisir depuis la galerie',
        'Medical Report Scanner': 'Scanner médical',
        'Upload your lab results for AI analysis.': 'Téléchargez vos résultats pour l\\'IA.',
        'Tap to Upload Report': 'Appuyez pour télécharger',
        'Use Camera or Gallery (Max 5MB)': 'Caméra ou Galerie (Max 5Mo)',
        'Analyzing Document...': 'Analyse du document...',
        'Analysis Complete': 'Analyse terminée',
        'Vitamin D Level': 'Niveau de vitamine D',
        'Suboptimal (22 ng/mL)': 'Sous-optimal (22 ng/mL)',
        'Recommendation: Increase sunlight exposure and consumption of fortified foods.': 'Recommandation: Augmentez l\\'exposition au soleil.',
        'Fasting Glucose': 'Glycémie à jeun',
        'Normal (85 mg/dL)': 'Normal (85 mg/dL)',
        'Recommendation: Maintain current carbohydrate intake.': 'Recommandation: Maintenez l\\'apport actuel en glucides.',
        'AI Health Assistant': 'Assistant de santé IA',
        'Type a message...': 'Écrivez un message...',
        'Typing...': 'En train d\\'écrire...',
        'Hello ': 'Bonjour ',
        '! I\\'ve reviewed your latest health metrics. How can I help you today?': '! J\\'ai examiné vos métriques. Comment puis-je vous aider ?',
        'Your Nutrition Plan': 'Votre plan nutritionnel',
        'AI-tailored based on your latest metrics.': 'Personnalisé par l\\'IA.',
        'Breakfast': 'Petit déjeuner',
        'Avocado Toast & Eggs': 'Toast à l\\'avocat et œufs',
        'Rich in healthy fats and protein to start the day. Recommended due to slightly lower Vitamin D.': 'Riche en graisses saines et en protéines.',
        'Lunch': 'Déjeuner',
        'Grilled Salmon Bowl': 'Bol de saumon grillé',
        'High in Omega-3 to help with cardiovascular optimization.': 'Riche en oméga-3.',
        'Settings': 'Paramètres',
        'Preferences': 'Préférences',
        'Dark Mode': 'Mode sombre',
        'Change application theme': 'Changer le thème de l\\'application',
        'Language': 'Langue',
        'Log Out': 'Se déconnecter',
      },
      'German': {
        'Welcome Back': 'Willkommen zurück',
        'Enter details to access health dashboard.': 'Geben Sie Details ein, um auf das Dashboard zuzugreifen.',
        'Email Address': 'E-Mail',
        'Password': 'Passwort',
        'Sign In': 'Anmelden',
        'NutriAI': 'NutriAI',
        'Home': 'Startseite',
        'Scanner': 'Scanner',
        'Chat': 'Chat',
        'Diet': 'Diät',
        'Welcome back, ': 'Willkommen zurück, ',
        'Here is your latest health overview.': 'Hier ist Ihre aktuelle Gesundheitsübersicht.',
        'Hydration': 'Flüssigkeitszufuhr',
        'Calories': 'Kalorien',
        'Health Score': 'Gesundheitswert',
        'Upload your latest blood report': 'Bericht hochladen',
        'Our AI can analyze your new report to adjust your nutrition plan immediately.': 'Unsere KI analysiert Ihren Bericht.',
        'Scan Report': 'Bericht scannen',
        'Upload Report': 'Bericht hochladen',
        'Take a Photo (Camera)': 'Foto machen (Kamera)',
        'Choose from Photo Gallery': 'Aus der Galerie wählen',
        'Medical Report Scanner': 'Medizinischer Berichts-Scanner',
        'Upload your lab results for AI analysis.': 'Laden Sie Ihre Laborergebnisse hoch.',
        'Tap to Upload Report': 'Tippen zum Hochladen',
        'Use Camera or Gallery (Max 5MB)': 'Kamera oder Galerie nutzen (Max 5MB)',
        'Analyzing Document...': 'Dokument wird analysiert...',
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
        'Hello ': 'Hallo ',
        '! I\\'ve reviewed your latest health metrics. How can I help you today?': '! Ich habe ihre Metriken geprüft. Was kann ich tun?',
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
        'Language': 'Sprache',
        'Log Out': 'Abmelden',
      }
    };
    return localizedValues[lang]?[this] ?? this;
  }
}
'''
    content = content.replace('''  void setLanguage(String lang) {
    language = lang;
    notifyListeners();
  }
}''', extension)

    # Convert const [] to [] where children uses const Text
    content = content.replace('const [', '[')

    strings_to_localize = [
        "'Welcome Back'",
        "'Enter details to access health dashboard.'",
        "'Email Address'",
        "'Password'",
        "'Sign In'",
        "'NutriAI'",
        "'Home'",
        "'Scanner'",
        "'Chat'",
        "'Diet'",
        "'Here is your latest health overview.'",
        "'Hydration'",
        "'Calories'",
        "'Health Score'",
        "'Upload your latest blood report'",
        "'Our AI can analyze your new report to adjust your nutrition plan immediately.'",
        "'Scan Report'",
        "'Upload Report'",
        "'Take a Photo (Camera)'",
        "'Choose from Photo Gallery'",
        "'Medical Report Scanner'",
        "'Upload your lab results for AI analysis.'",
        "'Tap to Upload Report'",
        "'Use Camera or Gallery (Max 5MB)'",
        "'Analyzing Document...'",
        "'Analysis Complete'",
        "'Vitamin D Level'",
        "'Suboptimal (22 ng/mL)'",
        "'Recommendation: Increase sunlight exposure and consumption of fortified foods.'",
        "'Fasting Glucose'",
        "'Normal (85 mg/dL)'",
        "'Recommendation: Maintain current carbohydrate intake.'",
        "'AI Health Assistant'",
        "'Type a message...'",
        "'Typing...'",
        "'Your Nutrition Plan'",
        "'AI-tailored based on your latest metrics.'",
        "'Breakfast'",
        "'Avocado Toast & Eggs'",
        "'Rich in healthy fats and protein to start the day. Recommended due to slightly lower Vitamin D.'",
        "'Lunch'",
        "'Grilled Salmon Bowl'",
        "'High in Omega-3 to help with cardiovascular optimization.'",
        "'Settings'",
        "'Preferences'",
        "'Dark Mode'",
        "'Change application theme'",
        "'Language'",
        "'Log Out'",
    ]

    for s in strings_to_localize:
        content = content.replace(f'const Text({s})', f'Text({s}.tr)')
        content = content.replace(f'const Text({s}', f'Text({s}.tr')
        content = content.replace(f'Text({s})', f'Text({s}.tr)')
        content = content.replace(f'Text({s}', f'Text({s}.tr')
        content = content.replace(f'label: {s}', f'label: {s}.tr')
        content = content.replace(f'hintText: {s}', f'hintText: {s}.tr')

    content = content.replace("'Welcome back, $globalUserName 👋'", "'Welcome back, '.tr + (globalUserName ?? '') + ' 👋'")
    content = content.replace('"Hello $globalUserName! I\\'ve reviewed your latest health metrics. How can I help you today?"', "'Hello '.tr + (globalUserName ?? '') + '! I\\'ve reviewed your latest health metrics. How can I help you today?'.tr")

    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
