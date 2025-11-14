# docker/cost.Dockerfile

FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y aws-cli && \
    pip install boto3 && \
    rm -rf /var/lib/apt/lists/*

COPY cost_analyzer.py .

ENTRYPOINT ["python3", "./cost_analyzer.py"]