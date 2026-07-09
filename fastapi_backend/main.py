import os
import json
import pandas as pd
import google.generativeai as genai
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from dotenv import load_dotenv

load_dotenv(override=True)

app = FastAPI(title="NutriScan ML Backend")

# Setup CORS Middleware for Flutter communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load the .env file securely to get GEMINI_API_KEY
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    print("WARNING: GEMINI_API_KEY is not set. Please check your .env file.")
else:
    genai.configure(api_key=api_key)
    print(f"INFO: Gemini configured using key: {api_key[:4]}...{api_key[-4:]}")
    if "VIt" in api_key:
        print("CRITICAL WARNING: You are still using the BROKEN API key with capital 'I'!")
    elif "Vit" in api_key:
        print("SUCCESS: You are using the CORRECT API key with lowercase 'i'.")

# Load Parameter Mapping (Optional now that we use rule-based, but kept for reference)
with open("param_mapping.json", "r") as f:
    param_mapping = json.load(f)

@app.post("/api/analyze-report")
async def analyze_report(
    image: UploadFile = File(...),
    diet_type: str = Form(...), # 'veg' or 'non-veg'
    allergies: str = Form(...)
):
    try:
        contents = await image.read()
        
        # ==========================================
        # Pipeline Step 1: OCR Extraction via Gemini
        model_vision = genai.GenerativeModel('gemini-2.5-flash')
        
        prompt_ocr = """
        You are a medical lab report parser. Extract the following 8 parameters from the image: 
        [Fasting Blood Sugar, Total Cholesterol, LDL, HDL, Triglycerides, Hemoglobin, Vitamin D, Vitamin B12].
        Return ONLY a JSON dictionary where keys are the parameter names exactly as listed above, 
        and values are the numeric values extracted. Do not include units in the values.
        If a parameter is not found, set its value to null.
        Example: {"Fasting Blood Sugar": 85.5, "Total Cholesterol": 180, "LDL": null, "HDL": 45, "Triglycerides": 120, "Hemoglobin": 14.2, "Vitamin D": 32, "Vitamin B12": 400}
        """
        
        image_parts = [{"mime_type": image.content_type, "data": contents}]
        response_ocr = model_vision.generate_content([prompt_ocr, image_parts[0]])
        
        try:
            clean_json = response_ocr.text.replace('```json', '').replace('```', '').strip()
            extracted_data = json.loads(clean_json)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to parse OCR JSON from Gemini: {str(e)} \nRaw output: {response_ocr.text}")
        
        # ==========================================
        # Pipeline Step 2: Rule-Based Classification
        # ==========================================
        ranges = {
            "Fasting Blood Sugar": (70, 99),
            "Total Cholesterol": (120, 200),
            "LDL": (40, 100),
            "HDL": (40, 10000), # Higher is better
            "Triglycerides": (50, 150),
            "Hemoglobin": (13.5, 17.5),
            "Vitamin D": (30, 100),
            "Vitamin B12": (200, 900)
        }
        
        analyzed_results = {}
        out_of_range = []
        
        for param, value in extracted_data.items():
            if value is not None and param in ranges:
                try:
                    val_float = float(value)
                    low, high = ranges[param]
                    
                    if param == "HDL":
                        status = "Normal" if val_float >= low else "Low"
                    else:
                        if val_float < low:
                            status = "Low"
                        elif val_float > high:
                            status = "High"
                        else:
                            status = "Normal"
                    
                    analyzed_results[param] = {
                        "value": val_float,
                        "status": status
                    }
                    
                    if status != "Normal":
                        out_of_range.append(f"{param} is {status} ({val_float})")
                except ValueError:
                    analyzed_results[param] = {"value": value, "status": "Invalid format"}
            else:
                 analyzed_results[param] = {"value": value, "status": "Not extracted or unknown"}

                 
        # ==========================================
        # Pipeline Step 3: Generative Meal Plan
        model_text = genai.GenerativeModel('gemini-2.5-flash')
        
        prompt_meals = f"""
        You are an expert nutritionist for NutriScan. The user's lab report shows the following out-of-range parameters:
        {json.dumps(out_of_range)}
        
        CRITICAL REQUIREMENTS:
        1. The user's diet type is strictly: {diet_type}. Ensure every meal strictly adheres to this (e.g., absolutely no meat if {diet_type} is veg, but if {diet_type} is non-veg, you MUST include non-veg items).
        2. ALLERGIES: The user is allergic to or dislikes "{allergies}". YOU MUST NOT INCLUDE ANY MEALS OR INGREDIENTS CONTAINING "{allergies}". If they are allergic to a specific item (e.g. oatmeal), REPLACE ONLY that specific item with a suitable alternative. Do NOT generate a completely different meal plan just because of one allergy.
        3. VARIETY: Do NOT repeat food items across breakfast, lunch, and dinner. Provide high variety.
        4. TARGETED NUTRITION: The meals MUST directly help heal the specific out-of-range parameters listed above.

        Generate a diverse 1-day meal plan based on the above constraints.
        Format as pure JSON like this:
        {{
            "breakfast": [
                {{"name": "Food Name", "portion": "Portion size", "reason": "Why it helps specific parameters"}}
            ],
            "lunch": [
                {{"name": "Food Name", "portion": "Portion size", "reason": "Why it helps specific parameters"}}
            ],
            "dinner": [
                {{"name": "Food Name", "portion": "Portion size", "reason": "Why it helps specific parameters"}}
            ]
        }}
        Respond ONLY with the JSON object.
        """
        
        response_meals = model_text.generate_content(prompt_meals)
        
        try:
            clean_meals_json = response_meals.text.replace('```json', '').replace('```', '').strip()
            meal_plan = json.loads(clean_meals_json)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to parse Meal Plan JSON from Gemini: {str(e)} \nRaw output: {response_meals.text}")

        # Return the final structured JSON back to the Flutter client
        return {
            "metrics": analyzed_results,
            "recommendations": meal_plan
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class UpdateDietRequest(BaseModel):
    out_of_range: List[str]
    diet_type: str
    allergies: str

@app.post("/api/update-diet")
async def update_diet(request: UpdateDietRequest):
    try:
        model_text = genai.GenerativeModel('gemini-2.5-flash')
        
        prompt_meals = f"""
        You are an expert nutritionist for NutriScan. The user's lab report shows the following out-of-range parameters:
        {json.dumps(request.out_of_range)}
        
        CRITICAL REQUIREMENTS:
        1. The user's diet type is strictly: {request.diet_type}. Ensure every meal strictly adheres to this (e.g., absolutely no meat if {request.diet_type} is veg, but if {request.diet_type} is non-veg, you MUST include non-veg items).
        2. ALLERGIES: The user is allergic to or dislikes "{request.allergies}". YOU MUST NOT INCLUDE ANY MEALS OR INGREDIENTS CONTAINING "{request.allergies}". If they are allergic to a specific item (e.g. oatmeal), REPLACE ONLY that specific item with a suitable alternative. Do NOT generate a completely different meal plan just because of one allergy.
        3. VARIETY: Do NOT repeat food items across breakfast, lunch, and dinner. Provide high variety.
        4. TARGETED NUTRITION: The meals MUST directly help heal the specific out-of-range parameters listed above.

        Generate a diverse 1-day meal plan based on the above constraints.
        Format as pure JSON like this:
        {{
            "breakfast": [
                {{"name": "Food Name", "portion": "Portion size", "reason": "Why it helps specific parameters"}}
            ],
            "lunch": [
                {{"name": "Food Name", "portion": "Portion size", "reason": "Why it helps specific parameters"}}
            ],
            "dinner": [
                {{"name": "Food Name", "portion": "Portion size", "reason": "Why it helps specific parameters"}}
            ]
        }}
        Respond ONLY with the JSON object.
        """
        
        response_meals = model_text.generate_content(prompt_meals)
        
        try:
            clean_meals_json = response_meals.text.replace('```json', '').replace('```', '').strip()
            meal_plan = json.loads(clean_meals_json)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to parse Meal Plan JSON from Gemini: {str(e)} \nRaw output: {response_meals.text}")

        return {"recommendations": meal_plan}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class ChatRequest(BaseModel):
    message: str
    history: List[dict] # list of {"role": "user"/"model", "parts": ["text"]}
    context: str

@app.post("/api/chat")
async def chat_endpoint(request: ChatRequest):
    try:
        model = genai.GenerativeModel('gemini-1.5-flash', system_instruction=request.context)
        
        # Convert incoming history format to the format google.generativeai expects
        formatted_history = []
        for msg in request.history:
            formatted_history.append({"role": msg["role"], "parts": msg["parts"]})
            
        chat = model.start_chat(history=formatted_history)
        response = chat.send_message(request.message)
        
        return {"response": response.text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
