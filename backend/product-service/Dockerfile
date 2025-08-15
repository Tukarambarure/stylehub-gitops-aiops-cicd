## Build stage
FROM python:3.9-slim AS builder

# Set working directory inside container
WORKDIR /app

# Install system dependencies needed for building Python packages
# - gcc is required to build some Python packages from source
# - removing apt lists reduces image size
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
# Use --no-cache-dir to avoid caching wheels and save space
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create data directory (mounted as a volume by docker-compose)
RUN mkdir -p data

## Runtime stage
FROM python:3.9-slim AS runtime

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install only runtime dependencies (no gcc needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Python packages from builder stage
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code from builder stage
COPY --from=builder /app/app.py /app/
COPY --from=builder /app/requirements.txt /app/

# Create data directory and set ownership
RUN mkdir -p data && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port used by the Flask app
EXPOSE 5001

# Start the application (replace with gunicorn for production)
CMD ["python", "app.py"]