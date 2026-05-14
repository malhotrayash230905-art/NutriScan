import pandas as pd
import pickle
import os

# load model safely
MODEL_PATH = os.path.join(os.path.dirname(__file__), "model.pkl")
model = pickle.load(open(MODEL_PATH, "rb"))

def predict_diet(values):
    df = pd.DataFrame([{
        "hba1c": values["hba1c"],
        "glucose": values["glucose"],
        "tsh": values["tsh"]
    }])

    prediction = model.predict(df)[0]

    return {
        "low_carb": int(prediction[0]),
        "low_sugar": int(prediction[1]),
        "thyroid_diet": int(prediction[2])
    }