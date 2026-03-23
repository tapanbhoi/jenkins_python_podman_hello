#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-/usr/bin/python3}"
ALLURE_BIN="${ALLURE_BIN:-/opt/homebrew/bin/allure}"
VENV_DIR="${PROJECT_DIR}/.venv"
BUILD_OUTPUT_DIR="${PROJECT_DIR}/build-output"
REPORT_DIR="${PROJECT_DIR}/reports"
JUNIT_DIR="${REPORT_DIR}/junit"
ALLURE_RESULTS_DIR="${REPORT_DIR}/allure-results"
ALLURE_HTML_DIR="${REPORT_DIR}/allure-html"

rm -rf "${VENV_DIR}" "${BUILD_OUTPUT_DIR}" "${REPORT_DIR}"
mkdir -p "${BUILD_OUTPUT_DIR}" "${JUNIT_DIR}" "${ALLURE_RESULTS_DIR}"

"${PYTHON_BIN}" -m venv "${VENV_DIR}"
. "${VENV_DIR}/bin/activate"
python -m pip install --upgrade pip
python -m pip install -r "${PROJECT_DIR}/requirements.txt"

python "${PROJECT_DIR}/hello.py" | tee "${BUILD_OUTPUT_DIR}/hello-output.txt"
cp "${PROJECT_DIR}/hello.py" "${BUILD_OUTPUT_DIR}/hello.py"

pytest -v \
    -c "${PROJECT_DIR}/pytest.ini" \
    "${PROJECT_DIR}/tests" \
    --junitxml="${JUNIT_DIR}/results.xml" \
    --alluredir="${ALLURE_RESULTS_DIR}"

if [ -x "${ALLURE_BIN}" ]; then
    "${ALLURE_BIN}" generate "${ALLURE_RESULTS_DIR}" --clean -o "${ALLURE_HTML_DIR}"
fi

echo "Verification flow completed successfully."
echo "JUnit report: ${JUNIT_DIR}/results.xml"
echo "Allure report: ${ALLURE_HTML_DIR}/index.html"
