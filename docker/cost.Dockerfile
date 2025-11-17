# docker/cost.Dockerfile

FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        unzip \
        && \
    pip install --no-cache-dir boto3 awscli pandas numpy && \
    rm -rf /var/lib/apt/lists/*

COPY cost_analyzer.py .

ENTRYPOINT ["python3", "./cost_analyzer.py"]