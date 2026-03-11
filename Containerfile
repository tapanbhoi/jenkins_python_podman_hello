FROM python:3.12-slim
WORKDIR /app
COPY artifact-content/ /app/
CMD ["python", "/app/hello.py"]
