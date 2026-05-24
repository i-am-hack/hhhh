# Build Stage (Frontend)
FROM node:20-slim AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ ./
RUN npm run build

# Final Stage (Backend + Frontend Assets)
FROM python:3.12-slim

# Install FFmpeg, unzip, and other dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy backend requirements and install
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir gunicorn uvicorn

# Copy backend code
COPY backend/ ./backend/

# Copy built frontend assets from previous stage
COPY --from=frontend-build /app/frontend/dist ./frontend/dist

# Create downloads directory
RUN mkdir -p /app/downloads

# Set PYTHONPATH
ENV PYTHONPATH=/app

# Set environment variable for port
ENV PORT=10000

# Expose port
EXPOSE 10000

# Run the application
CMD gunicorn backend.main:app -w 2 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT --timeout 120
