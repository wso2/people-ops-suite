from langchain_openai import ChatOpenAI

import os
from dotenv import load_dotenv

load_dotenv()

llm = ChatOpenAI(
    model_name="gpt-4o", temperature=0, openai_api_key=os.getenv("OPENAI_API_KEY")
)
