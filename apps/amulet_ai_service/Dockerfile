FROM python:3.11-slim

WORKDIR /app
COPY apps/amulet_ai_service/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy the entire apps directory to maintain the module structure
COPY apps /app/apps
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
