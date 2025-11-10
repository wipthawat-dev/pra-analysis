FROM python:3.11-slim

WORKDIR /app
COPY apps/amulet-ai-service/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy the entire apps directory to maintain the module structure
COPY apps /app/apps
# Rename amulet-ai-service to amulet_ai_service (Python modules can't have dashes)
RUN mv /app/apps/amulet-ai-service /app/apps/amulet_ai_service
# Copy scripts
COPY scripts /app/scripts
# Copy shared schemas (if directory exists, it will be copied)
COPY shared /app/shared

# Set PYTHONPATH to include /app so Python can find the apps module
ENV PYTHONPATH=/app:$PYTHONPATH

# Keep working directory at /app (not /app/apps/amulet_ai_service)
# This allows Python to find the apps module correctly
WORKDIR /app

EXPOSE 8000
CMD ["uvicorn", "apps.amulet_ai_service.main:app", "--host", "0.0.0.0", "--port", "8000"]
