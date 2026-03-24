#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-/usr/bin/python3}"
PODMAN_BIN="${PODMAN_BIN:-/opt/podman/bin/podman}"
PODMAN_MACHINE="${PODMAN_MACHINE:-jenkins-podman}"
WORK_DIR="${PROJECT_DIR}/work"
ARTIFACT_CONTENT_DIR="${PROJECT_DIR}/artifact-content"
ARTIFACT_DIR="${PROJECT_DIR}/artifacts"
IMAGE_DIR="${PROJECT_DIR}/images"
IMAGE_NAME="${IMAGE_NAME:-local/hello-artifact:latest}"

rm -rf "${WORK_DIR}" "${ARTIFACT_CONTENT_DIR}" "${ARTIFACT_DIR}" "${IMAGE_DIR}"
mkdir -p "${WORK_DIR}" "${ARTIFACT_CONTENT_DIR}" "${ARTIFACT_DIR}" "${IMAGE_DIR}"

cp "${PROJECT_DIR}/hello.py" "${WORK_DIR}/hello.py"
"${PYTHON_BIN}" "${WORK_DIR}/hello.py" | tee "${ARTIFACT_CONTENT_DIR}/hello-output.txt"
cp "${WORK_DIR}/hello.py" "${ARTIFACT_CONTENT_DIR}/hello.py"

tar -czf "${ARTIFACT_DIR}/hello-artifact.tar.gz" -C "${ARTIFACT_CONTENT_DIR}" .
if ! "${PODMAN_BIN}" --connection "${PODMAN_MACHINE}" info >/dev/null 2>&1; then
    "${PODMAN_BIN}" machine start "${PODMAN_MACHINE}"
fi
"${PODMAN_BIN}" --connection "${PODMAN_MACHINE}" info >/dev/null
"${PODMAN_BIN}" --connection "${PODMAN_MACHINE}" build -t "${IMAGE_NAME}" -f "${PROJECT_DIR}/Containerfile" "${PROJECT_DIR}"
"${PODMAN_BIN}" --connection "${PODMAN_MACHINE}" save -o "${IMAGE_DIR}/hello-artifact-image.tar" "${IMAGE_NAME}"

echo "Artifact created at ${ARTIFACT_DIR}/hello-artifact.tar.gz"
echo "Image archive created at ${IMAGE_DIR}/hello-artifact-image.tar"
