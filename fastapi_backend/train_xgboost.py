import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import json

# Define the features and their WHO ranges for High, Normal, Low
# Since we will train a single model to predict status for ANY parameter,
# we need to pass the parameter type and its value.
# Actually, a better approach for ML:
# Model input: [Parameter_Type_Encoded, Value]
# Output: [Class: 0 (Low), 1 (Normal), 2 (High)]

parameters = [
    "Fasting Blood Sugar",
    "Total Cholesterol",
    "LDL",
    "HDL",
    "Triglycerides",
    "Hemoglobin",
    "Vitamin D",
    "Vitamin B12"
]

param_mapping = {p: i for i, p in enumerate(parameters)}
with open("param_mapping.json", "w") as f:
    json.dump(param_mapping, f)

# WHO Ranges (simplified for the model)
# Structure: {Param: (Low_threshold, High_threshold)}
# Example: Fasting Blood Sugar -> Normal is 70 to 99.
# Low < 70, High > 99
ranges = {
    "Fasting Blood Sugar": (70, 100),
    "Total Cholesterol": (120, 200),
    "LDL": (40, 100),
    "HDL": (40, 60), # HDL is tricky: high is good, low is bad. Normal is >40 (men) or >50 (women). Let's use 40 as low threshold, high is not really bad but let's say > 60 is high.
    "Triglycerides": (50, 150),
    "Hemoglobin": (12.0, 17.5),
    "Vitamin D": (30, 100),
    "Vitamin B12": (200, 900)
}

def determine_class(param, value):
    low, high = ranges[param]
    if value < low:
        return 0 # Low
    elif value > high:
        return 2 # High
    else:
        return 1 # Normal

data = []
# Generate synthetic data
np.random.seed(42)
for param in parameters:
    low, high = ranges[param]
    
    # Generate Low values
    low_values = np.random.uniform(low * 0.5, low - 0.1, 1000)
    for v in low_values:
        data.append([param_mapping[param], v, determine_class(param, v)])
        
    # Generate Normal values
    normal_values = np.random.uniform(low, high, 1000)
    for v in normal_values:
        data.append([param_mapping[param], v, determine_class(param, v)])
        
    # Generate High values
    high_values = np.random.uniform(high + 0.1, high * 1.5, 1000)
    for v in high_values:
        data.append([param_mapping[param], v, determine_class(param, v)])

df = pd.DataFrame(data, columns=["param_type", "value", "target"])

X = df[["param_type", "value"]]
y = df["target"]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = xgb.XGBClassifier(objective="multi:softmax", num_class=3, n_estimators=100, max_depth=3)
model.fit(X_train, y_train)

y_pred = model.predict(X_test)
print(f"Accuracy: {accuracy_score(y_test, y_pred):.4f}")

model.save_model("health_model.json")
print("Model saved to health_model.json")
print("Parameter mapping saved to param_mapping.json")
