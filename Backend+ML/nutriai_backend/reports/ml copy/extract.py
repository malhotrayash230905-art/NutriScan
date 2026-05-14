import pdfplumber
import re

def extract_values(pdf_path):
    text = ""

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text += page.extract_text() or ""

    def find(pattern):
        match = re.search(pattern, text, re.IGNORECASE)
        return float(match.group(1)) if match else None

    return {
        "hba1c": find(r"HbA1c.*?(\d+\.\d+)"),
        "glucose": find(r"average glucose.*?(\d+\.\d+)"),
        "tsh": find(r"TSH.*?(\d+\.\d+)")
    }