pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        timestamps()
    }

    environment {
        PYTHON_BIN = "/usr/bin/python3"
        PODMAN_BIN = "/opt/podman/bin/podman"
        ALLURE_BIN = "/opt/homebrew/bin/allure"
        VENV_DIR = "${WORKSPACE}/.venv"
        WORK_DIR = "${WORKSPACE}/work"
        ARTIFACT_CONTENT_DIR = "${WORKSPACE}/artifact-content"
        ARTIFACT_DIR = "${WORKSPACE}/artifacts"
        IMAGE_DIR = "${WORKSPACE}/images"
        REPORT_DIR = "${WORKSPACE}/reports"
        JUNIT_DIR = "${WORKSPACE}/reports/junit"
        ALLURE_RESULTS_DIR = "${WORKSPACE}/reports/allure-results"
        ALLURE_HTML_DIR = "${WORKSPACE}/reports/allure-html"
        IMAGE_NAME = "local/hello-artifact:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Workspace') {
            steps {
                sh '''
                    set -euo pipefail
                    rm -rf "${VENV_DIR}" "${WORK_DIR}" "${ARTIFACT_CONTENT_DIR}" "${ARTIFACT_DIR}" "${IMAGE_DIR}" "${REPORT_DIR}"
                    mkdir -p "${WORK_DIR}" "${ARTIFACT_CONTENT_DIR}" "${ARTIFACT_DIR}" "${IMAGE_DIR}" "${JUNIT_DIR}" "${ALLURE_RESULTS_DIR}"
                    cp hello.py "${WORK_DIR}/hello.py"
                '''
            }
        }

        stage('Setup Python Test Environment') {
            steps {
                sh '''
                    set -euo pipefail
                    "${PYTHON_BIN}" -m venv "${VENV_DIR}"
                    . "${VENV_DIR}/bin/activate"
                    python -m pip install --upgrade pip
                    python -m pip install -r requirements.txt
                '''
            }
        }

        stage('Run Script On Agent') {
            steps {
                sh '''
                    set -euo pipefail
                    "${PYTHON_BIN}" "${WORK_DIR}/hello.py" | tee "${ARTIFACT_CONTENT_DIR}/hello-output.txt"
                    cp "${WORK_DIR}/hello.py" "${ARTIFACT_CONTENT_DIR}/hello.py"
                '''
            }
        }

        stage('Verify Script And Generate Test Reports') {
            steps {
                sh '''
                    set -euo pipefail
                    . "${VENV_DIR}/bin/activate"
                    pytest -v \
                      --junitxml="${JUNIT_DIR}/results.xml" \
                      --alluredir="${ALLURE_RESULTS_DIR}"

                    if [ -x "${ALLURE_BIN}" ]; then
                        "${ALLURE_BIN}" generate "${ALLURE_RESULTS_DIR}" --clean -o "${ALLURE_HTML_DIR}"
                    fi
                '''
            }
        }

        stage('Create Artifact') {
            steps {
                sh '''
                    set -euo pipefail
                    tar -czf "${ARTIFACT_DIR}/hello-artifact.tar.gz" -C "${ARTIFACT_CONTENT_DIR}" .
                    ls -lh "${ARTIFACT_DIR}/hello-artifact.tar.gz"
                '''
            }
        }

        stage('Build Podman Image') {
            steps {
                sh '''
                    set -euo pipefail
                    if ! "${PODMAN_BIN}" info >/dev/null 2>&1; then
                        "${PODMAN_BIN}" machine start
                    fi
                    "${PODMAN_BIN}" info >/dev/null
                    "${PODMAN_BIN}" build -t "${IMAGE_NAME}" -f Containerfile .
                    "${PODMAN_BIN}" save -o "${IMAGE_DIR}/hello-artifact-image.tar" "${IMAGE_NAME}"
                    ls -lh "${IMAGE_DIR}/hello-artifact-image.tar"
                '''
            }
        }
    }

    post {
        always {
            junit testResults: 'reports/junit/results.xml', allowEmptyResults: false
            archiveArtifacts artifacts: 'artifacts/*,images/*,reports/**/*,artifact-content/*', fingerprint: true, allowEmptyArchive: true
            script {
                if (fileExists('reports/allure-results') && fileExists('/opt/homebrew/bin/allure')) {
                    try {
                        allure includeProperties: false, jdk: '', results: [[path: 'reports/allure-results']]
                    } catch (err) {
                        echo "Allure Jenkins plugin is not available. HTML report was archived from reports/allure-html instead."
                    }
                }
            }
        }
    }
}
