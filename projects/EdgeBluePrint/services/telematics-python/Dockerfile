FROM python@sha256:a0f57064cbdcd6285fa45f51237ab0b35ea8ebaed06a1f5973e89e19dfb86704 AS builder
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
WORKDIR /build
COPY requirements.txt .
RUN python -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir --upgrade pip==26.2.2 && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

FROM python@sha256:a0f57064cbdcd6285fa45f51237ab0b35ea8ebaed06a1f5973e89e19dfb86704 AS runner
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV PATH="/opt/venv/bin:$PATH" PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY --from=builder /opt/venv /opt/venv
COPY main.py .
RUN rm -rf /opt/venv/lib/python3.12/site-packages/pip* /opt/venv/lib/python3.12/site-packages/setuptools* && useradd --create-home --uid 10001 appuser && mkdir -p /app/buffer && chown -R appuser:appuser /app
USER appuser
CMD ["python", "-u", "main.py"]
