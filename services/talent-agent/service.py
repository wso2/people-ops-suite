from fastapi import FastAPI, UploadFile, File
from kor.extraction import create_extraction_chain
from pdf_utils import extract_text
from llm_utils import llm
from schemas import candidate_schema
from validation import format_candidate_data
import shutil
import os

app = FastAPI()

@app.post("/resumes/parse")
async def extract_resumes(files: list[UploadFile] = File(...)):
    os.makedirs("temp", exist_ok=True)
    structuredObjects = []
    
    for file in files:
        file_location = f"temp/{file.filename}"
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        resume_content = extract_text(file_location)
        chain = create_extraction_chain(llm, candidate_schema, encoder_or_encoder_class="json", input_formatter=None)
        output = chain.invoke(resume_content)["data"]
        structuredObjects.append(format_candidate_data(output))
        os.remove(file_location)
    
    return {"structuredObjects": structuredObjects}
