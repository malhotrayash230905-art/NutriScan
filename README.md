# NutriScan 🍏🏥

**NutriScan** is an intelligent mobile application designed to bridge the gap between medical lab reports and actionable nutritional guidance. Built with Flutter for a seamless cross-platform experience and powered by a robust Python FastAPI backend, it acts as your personal AI-driven medical analyst and nutritionist.

## 🚀 Features

- **Smart Lab Report Parsing (OCR)**: Upload your medical lab reports, and NutriScan will automatically extract 8 critical parameters:
  - Fasting Blood Sugar
  - Total Cholesterol
  - LDL
  - HDL
  - Triglycerides
  - Hemoglobin
  - Vitamin D
  - Vitamin B12
- **Rule-Based Health Classification**: Safely categorizes your extracted metrics into "Normal", "High", or "Low" based on standard medical ranges.
- **AI-Powered Generative Meal Planning**: Utilizing Google's cutting-edge **Gemini 2.5 Flash**, the app generates a highly personalized 1-day meal plan (Breakfast, Lunch, Dinner). The recommendations specifically target your out-of-range parameters to help you heal naturally.
- **Diet & Allergy Aware**: Strict adherence to your dietary preferences (Vegetarian or Non-Vegetarian) and allergies. The AI ensures no harmful or disliked ingredients are included in your personalized plan.
- **Conversational AI Health Assistant**: An interactive chat interface powered by Gemini to answer your health, diet, and nutrition-related queries on the go.

## 🛠️ Technology Stack

### **Frontend (Mobile App)**
- **Flutter & Dart**: For building a beautiful, natively compiled, cross-platform mobile user interface.

### **Backend & APIs**
- **FastAPI (Python)**: A modern, fast, high-performance web framework for building APIs.
- **Uvicorn**: ASGI server for running the FastAPI application.
- **Docker**: For containerizing the backend to ensure consistent deployment.

### **Machine Learning & AI Models**
- **Google Gemini 2.5 Flash (Vision & Text)**: 
  - **Vision Model**: Used for robust OCR extraction of complex, unstructured medical reports directly from images. It returns precisely structured JSON data.
  - **Text Model**: Acts as the expert nutritionist generating the meal plans based on rule-based prompts and constraints, as well as powering the conversational health chatbot.

## 🧠 How the ML Pipeline Works

1. **OCR Extraction via Gemini Vision**: The user uploads an image of their blood test report. The backend sends the image to `gemini-2.5-flash` with a strict prompt to extract the 8 specific parameters, handling formatting inconsistencies in various lab reports and returning clean JSON.
2. **Rule-Based Validation**: The Python backend parses the extracted data and runs it through predefined medical range rules to flag any parameters that are out of bounds. This hybrid approach ensures deterministic safety in health evaluations.
3. **Generative Meal Plan**: The flagged parameters, along with the user's diet type and allergies, are sent to the Gemini Text model. A highly constrained prompt forces the model to generate a strict, varied, and safe meal plan designed explicitly to address the flagged health issues.
4. **Chatbot Context**: The app utilizes Gemini's chat sessions (`start_chat`) to maintain conversational history, allowing users to ask follow-up questions about their health metrics or meal plans.

## 📂 Project Structure
- `/lib`: Contains the Flutter mobile application source code (UI, state management, API services).
- `/fastapi_backend`: Contains the Python backend code (`main.py`), requirements, and `Dockerfile`.

## ⚙️ Running Locally

### Backend
1. Navigate to the `fastapi_backend` directory.
2. Create a `.env` file and add your Google Gemini API key: `GEMINI_API_KEY=your_api_key_here`.
3. Install dependencies: `pip install -r requirements.txt`.
4. Run the server: `uvicorn main:app --host 0.0.0.0 --port 8000 --reload`.

### Frontend
1. Make sure you have Flutter installed.
2. Run `flutter pub get` in the root directory.
3. Start the application on an emulator or physical device using `flutter run`.
