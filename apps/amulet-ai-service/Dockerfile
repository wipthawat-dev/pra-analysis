FROM python:3.11-slim

WORKDIR /app
COPY apps/amulet-ai-service/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY apps/amulet-ai-service /app
COPY scripts /app/scripts

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
