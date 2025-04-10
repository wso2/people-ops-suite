from score import evaluate_candidate
from fastapi import FastAPI, UploadFile, File, HTTPException, Request
from kor.extraction import create_extraction_chain
from pdf_utils import extract_text
from llm_utils import llm
from schemas import candidate_schema
from validation import format_candidate_data
import shutil
import os

app = FastAPI()

@app.post("/resumes/parse")
async def extract_resume(request: Request):
    data: bytes = await request.body()

    os.makedirs("temp", exist_ok=True)
    file_location = "temp/temp_resume.pdf"

    try:
        with open(file_location, "wb") as f:
            f.write(data)

        resume_content = extract_text(file_location)
        chain = create_extraction_chain(
            llm,
            candidate_schema,
            encoder_or_encoder_class="json",
            input_formatter=None
        )
        output = chain.invoke(resume_content)["data"]
        structured_object = format_candidate_data(output)
    finally:
        if os.path.exists(file_location):
            os.remove(file_location)

    return {"structuredObject": structured_object}

@app.post("/resumes/similarity")
async def get_scores(request: Request):
    try:
        raw_body = await request.body()

        if not raw_body:
            raise HTTPException(status_code=400, detail="Request body is empty")
            
        try:
            data = await request.json()
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"JSON parsing error: {str(e)}")
            
        structured_object = data["structuredObject"]
        required_skills = data["requiredSkills"]
        results = evaluate_candidate(structured_object, required_skills)
        return results
    except Exception as e:
        print(f"Error: {type(e).__name__}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
