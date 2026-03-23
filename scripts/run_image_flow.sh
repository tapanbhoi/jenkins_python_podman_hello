#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-/usr/bin/python3}"
PODMAN_BIN="${PODMAN_BIN:-/opt/podman/bin/podman}"
PODMAN_MACHINE="${PODMAN_MACHINE:-podman-machine-default}"
BUILD_OUTPUT_DIR="${PROJECT_DIR}/build-output"
PACKAGE_SRC_DIR="${PROJECT_DIR}/package-src"
ARTIFACT_DIR="${PROJECT_DIR}/artifacts"
IMAGE_DIR="${PROJECT_DIR}/images"
IMAGE_NAME="${IMAGE_NAME:-local/hello-artifact:latest}"

rm -rf "${BUILD_OUTPUT_DIR}" "${PACKAGE_SRC_DIR}" "${ARTIFACT_DIR}" "${IMAGE_DIR}"
mkdir -p "${BUILD_OUTPUT_DIR}" "${PACKAGE_SRC_DIR}" "${ARTIFACT_DIR}" "${IMAGE_DIR}"

"${PYTHON_BIN}" "${PROJECT_DIR}/hello.py" | tee "${BUILD_OUTPUT_DIR}/hello-output.txt"
cp "${PROJECT_DIR}/hello.py" "${BUILD_OUTPUT_DIR}/hello.py"
cp "${PROJECT_DIR}/hello.py" "${PACKAGE_SRC_DIR}/hello.py"
"${PYTHON_BIN}" -m zipapp "${PACKAGE_SRC_DIR}" -m "hello:main" -o "${BUILD_OUTPUT_DIR}/hello-app.pyz"

tar -czf "${ARTIFACT_DIR}/hello-artifact.tar.gz" -C "${BUILD_OUTPUT_DIR}" .
if ! "${PODMAN_BIN}" --connection "${PODMAN_MACHINE}" info >/dev/null 2>&1; then
    "${PODMAN_BIN}" machine start "${PODMAN_MACHINE}"
fi
"${PODMAN_BIN}" --connection "${PODMAN_MACHINE}" info >/dev/null
"${PODMAN_BIN}" --connection "${PODMAN_MACHINE}" build -t "${IMAGE_NAME}" -f "${PROJECT_DIR}/Containerfile" "${PROJECT_DIR}"
"${PODMAN_BIN}" --connection "${PODMAN_MACHINE}" save -o "${IMAGE_DIR}/hello-artifact-image.tar" "${IMAGE_NAME}"

echo "Artifact created at ${ARTIFACT_DIR}/hello-artifact.tar.gz"
echo "Image archive created at ${IMAGE_DIR}/hello-artifact-image.tar"
