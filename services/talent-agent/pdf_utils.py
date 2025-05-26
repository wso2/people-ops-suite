import pdfplumber
from pdf2image import convert_from_path
import pytesseract
from PIL import Image


def extract_text(file_path):
    text = ""

    if file_path.lower().endswith(".pdf"):
        with pdfplumber.open(file_path) as pdf:
            for page in pdf.pages:
                extracted_text = page.extract_text()
                if extracted_text:
                    text += extracted_text + "\n"

                for annot in page.annots or []:
                    if annot.get("uri"):
                        link = annot["uri"]
                        text += f" [Link: {link}] "

        if len(text) < 100:
            images = convert_from_path(file_path)
            for img in images:
                text += pytesseract.image_to_string(img)

    elif file_path.lower().endswith((".png", ".jpg", ".jpeg", ".bmp", ".tiff", ".gif")):
        img = Image.open(file_path)
        text = pytesseract.image_to_string(img)

    else:
        raise ValueError("Unsupported file format. Please provide a PDF or an image.")

    return text
