FROM python:3.12-slim
WORKDIR /app
COPY build-output/hello-app.pyz /app/hello-app.pyz
COPY build-output/hello-output.txt /app/hello-output.txt
CMD ["python", "/app/hello-app.pyz"]
