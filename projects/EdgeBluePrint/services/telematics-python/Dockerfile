FROM python@sha256:b658b05ce9c4eb97ec6fc19424818a1f31993659c2b505a532f470e83807815d AS builder
RUN apk upgrade --no-cache
WORKDIR /build
COPY requirements.txt .
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --upgrade pip==26.2.2 \
    && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

FROM builder AS test-builder
COPY requirements-test.txt .
RUN /opt/venv/bin/pip install --no-cache-dir --requirement requirements-test.txt

FROM python@sha256:b658b05ce9c4eb97ec6fc19424818a1f31993659c2b505a532f470e83807815d AS runner
RUN apk upgrade --no-cache
WORKDIR /app
ENV PATH="/opt/venv/bin:$PATH" PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY --from=builder /opt/venv /opt/venv
COPY main.py .
RUN rm -rf /opt/venv/lib/python3.12/site-packages/pip* /opt/venv/lib/python3.12/site-packages/setuptools* \
    && adduser -D -u 10001 appuser \
    && mkdir -p /app/buffer \
    && chown -R appuser:appuser /app
USER appuser
CMD ["python", "-u", "main.py"]

FROM runner AS test
COPY --from=test-builder /opt/venv/lib/python3.12/site-packages /opt/venv/lib/python3.12/site-packages
COPY --chown=appuser:appuser test_main.py .
CMD ["python", "-m", "pytest", "-q", "test_main.py"]
