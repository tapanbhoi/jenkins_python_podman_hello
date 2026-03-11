#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-/usr/bin/python3}"
PODMAN_BIN="${PODMAN_BIN:-/opt/podman/bin/podman}"
ALLURE_BIN="${ALLURE_BIN:-/opt/homebrew/bin/allure}"
VENV_DIR="${PROJECT_DIR}/.venv"
WORK_DIR="${PROJECT_DIR}/work"
ARTIFACT_CONTENT_DIR="${PROJECT_DIR}/artifact-content"
ARTIFACT_DIR="${PROJECT_DIR}/artifacts"
IMAGE_DIR="${PROJECT_DIR}/images"
REPORT_DIR="${PROJECT_DIR}/reports"
JUNIT_DIR="${REPORT_DIR}/junit"
ALLURE_RESULTS_DIR="${REPORT_DIR}/allure-results"
ALLURE_HTML_DIR="${REPORT_DIR}/allure-html"
IMAGE_NAME="${IMAGE_NAME:-local/hello-artifact:latest}"

rm -rf "${VENV_DIR}" "${WORK_DIR}" "${ARTIFACT_CONTENT_DIR}" "${ARTIFACT_DIR}" "${IMAGE_DIR}" "${REPORT_DIR}"
mkdir -p "${WORK_DIR}" "${ARTIFACT_CONTENT_DIR}" "${ARTIFACT_DIR}" "${IMAGE_DIR}" "${JUNIT_DIR}" "${ALLURE_RESULTS_DIR}"

"${PYTHON_BIN}" -m venv "${VENV_DIR}"
. "${VENV_DIR}/bin/activate"
python -m pip install --upgrade pip
python -m pip install -r "${PROJECT_DIR}/requirements.txt"

cp "${PROJECT_DIR}/hello.py" "${WORK_DIR}/hello.py"
"${PYTHON_BIN}" "${WORK_DIR}/hello.py" | tee "${ARTIFACT_CONTENT_DIR}/hello-output.txt"
cp "${WORK_DIR}/hello.py" "${ARTIFACT_CONTENT_DIR}/hello.py"

pytest -v \
    -c "${PROJECT_DIR}/pytest.ini" \
    "${PROJECT_DIR}/tests" \
    --junitxml="${JUNIT_DIR}/results.xml" \
    --alluredir="${ALLURE_RESULTS_DIR}"

if [ -x "${ALLURE_BIN}" ]; then
    "${ALLURE_BIN}" generate "${ALLURE_RESULTS_DIR}" --clean -o "${ALLURE_HTML_DIR}"
fi

tar -czf "${ARTIFACT_DIR}/hello-artifact.tar.gz" -C "${ARTIFACT_CONTENT_DIR}" .
if ! "${PODMAN_BIN}" info >/dev/null 2>&1; then
    "${PODMAN_BIN}" machine start
fi
"${PODMAN_BIN}" info >/dev/null
"${PODMAN_BIN}" build -t "${IMAGE_NAME}" -f "${PROJECT_DIR}/Containerfile" "${PROJECT_DIR}"
"${PODMAN_BIN}" save -o "${IMAGE_DIR}/hello-artifact-image.tar" "${IMAGE_NAME}"

echo "Artifact created at ${ARTIFACT_DIR}/hello-artifact.tar.gz"
echo "Image archive created at ${IMAGE_DIR}/hello-artifact-image.tar"
echo "JUnit report created at ${JUNIT_DIR}/results.xml"
echo "Allure results created at ${ALLURE_RESULTS_DIR}"
if [ -d "${ALLURE_HTML_DIR}" ]; then
    echo "Allure HTML report created at ${ALLURE_HTML_DIR}/index.html"
fi
