# Voice Agent backend - FastAPI + Groq
FROM python:3.11-slim

WORKDIR /app

# System deps kept minimal; uvicorn[standard] pulls in what it needs for perf extras.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

ENV HOST=0.0.0.0
ENV PORT=8000
EXPOSE 8000

# Do not bake secrets into the image; pass GROQ_API_KEY etc. at runtime via
# --env-file .env or your orchestrator's secret manager.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
