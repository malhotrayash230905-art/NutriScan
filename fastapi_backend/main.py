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
import random

api_keys_raw = os.getenv("GEMINI_API_KEY", "")
api_keys = [k.strip() for k in api_keys_raw.split(",") if k.strip()]

if not api_keys:
    print("WARNING: GEMINI_API_KEY is not set. Please check your .env file.")
else:
    print(f"INFO: Found {len(api_keys)} API keys loaded for rotation.")
    for key in api_keys:
        if "VIt" in key:
            print(f"CRITICAL WARNING: The key {key[:4]}... is BROKEN (uses capital 'I')!")

def configure_random_gemini_key():
    if not api_keys:
        return
    key = random.choice(api_keys)
    genai.configure(api_key=key)
    return key


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
        active_key = configure_random_gemini_key()
        print(f"analyze_report using key: {active_key[:8]}...")
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
        active_key = configure_random_gemini_key()
        print(f"analyze_report meals using key: {active_key[:8]}...")
        model_text = genai.GenerativeModel('gemini-2.5-flash')
        
        prompt_meals = f"""
        You are an expert nutritionist for NutriScan. The user's lab report shows the following out-of-range parameters:
        {json.dumps(out_of_range)}
        
        CRITICAL REQUIREMENTS:
        1. DIET RESTRICTION (CRITICAL): The user's diet type is strictly: {diet_type.upper()}. If the diet is 'veg' or 'vegetarian', you MUST NOT include ANY meat, poultry, fish, or seafood. ALL meals must be 100% vegetarian. If the diet is 'non-veg', you SHOULD include meat, poultry, or fish where appropriate.
        2. ALLERGIES: The user is allergic to or dislikes "{allergies}". YOU MUST NOT INCLUDE ANY MEALS OR INGREDIENTS CONTAINING "{allergies}". If they are allergic to a specific item (e.g. oatmeal), REPLACE ONLY that specific item with a suitable alternative.
        3. VARIETY: Do NOT repeat food items across breakfast, lunch, and dinner. Provide high variety.
        4. TARGETED NUTRITION: The meals MUST directly help heal the specific out-of-range parameters listed above.
        5. RANDOMNESS & NO REPETITION: Generate highly diverse food options. Make sure to randomize your recommendations so different reports do not get the same standard meals. Pick unique, interesting recipes.

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
        
        response_meals = model_text.generate_content(
            prompt_meals,
            generation_config=genai.GenerationConfig(temperature=0.8)
        )
        
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
        active_key = configure_random_gemini_key()
        print(f"update_diet using key: {active_key[:8]}...")
        model_text = genai.GenerativeModel('gemini-2.5-flash')
        
        prompt_meals = f"""
        You are an expert nutritionist for NutriScan. The user's lab report shows the following out-of-range parameters:
        {json.dumps(request.out_of_range)}
        
        CRITICAL REQUIREMENTS:
        1. DIET RESTRICTION (CRITICAL): The user's diet type is strictly: {request.diet_type.upper()}. If the diet is 'veg' or 'vegetarian', you MUST NOT include ANY meat, poultry, fish, or seafood. ALL meals must be 100% vegetarian. If the diet is 'non-veg', you SHOULD include meat, poultry, or fish where appropriate.
        2. ALLERGIES: The user is allergic to or dislikes "{request.allergies}". YOU MUST NOT INCLUDE ANY MEALS OR INGREDIENTS CONTAINING "{request.allergies}". If they are allergic to a specific item (e.g. oatmeal), REPLACE ONLY that specific item with a suitable alternative.
        3. VARIETY: Do NOT repeat food items across breakfast, lunch, and dinner. Provide high variety.
        4. TARGETED NUTRITION: The meals MUST directly help heal the specific out-of-range parameters listed above.
        5. RANDOMNESS & NO REPETITION: Generate highly diverse food options. Make sure to randomize your recommendations so different reports do not get the same standard meals. Pick unique, interesting recipes.

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
        
        response_meals = model_text.generate_content(
            prompt_meals,
            generation_config=genai.GenerationConfig(temperature=0.8)
        )
        
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
        print(f"Received chat request: {request.message}")
        active_key = configure_random_gemini_key()
        print(f"chat_endpoint using key: {active_key[:8]}...")
        model = genai.GenerativeModel('gemini-2.5-flash', system_instruction=request.context)
        
        formatted_history = []
        for msg in request.history:
            formatted_history.append({"role": msg["role"], "parts": msg["parts"]})
            
        print("Starting chat with history length:", len(formatted_history))
        chat = model.start_chat(history=formatted_history)
        
        print("Sending message to Gemini...")
        response = await chat.send_message_async(request.message)
        print("Received response from Gemini!")
        
        return {"response": response.text}
    except Exception as e:
        print(f"Error in chat endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))
