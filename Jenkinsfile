pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        PYTHON_BIN = "/usr/bin/python3"
        PODMAN_BIN = "/opt/podman/bin/podman"
        ALLURE_BIN = "/opt/homebrew/bin/allure"
        PODMAN_MACHINE = "podman-machine-default"
        WORK_DIR = "${WORKSPACE}/work"
        BUILD_OUTPUT_DIR = "${WORKSPACE}/build-output"
        PACKAGE_SRC_DIR = "${WORKSPACE}/package-src"
        ARTIFACT_DIR = "${WORKSPACE}/artifacts"
        IMAGE_DIR = "${WORKSPACE}/images"
        REPORT_DIR = "${WORKSPACE}/reports"
        JUNIT_DIR = "${WORKSPACE}/reports/junit"
        ALLURE_RESULTS_DIR = "${WORKSPACE}/reports/allure-results"
        ALLURE_HTML_DIR = "${WORKSPACE}/reports/allure-html"
        IMAGE_REPO = "local/hello-artifact"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Branch Context') {
            steps {
                script {
                    def rawBranch = env.BRANCH_NAME ?: env.GIT_LOCAL_BRANCH ?: env.GIT_BRANCH ?: 'manual'
                    def effectiveBranch = rawBranch
                        .replaceFirst(/^refs\/heads\//, '')
                        .replaceFirst(/^origin\//, '')
                        .replaceFirst(/^\*\//, '')

                    env.EFFECTIVE_BRANCH_NAME = effectiveBranch
                    if (!(env.BRANCH_NAME?.trim())) {
                        env.BRANCH_NAME = effectiveBranch
                    }
                    env.SAFE_BRANCH_NAME = effectiveBranch.replaceAll(/[^A-Za-z0-9_.-]+/, '-')
                    env.BRANCH_IMAGE_NAME = "${env.IMAGE_REPO}:${env.SAFE_BRANCH_NAME}-${env.BUILD_NUMBER}"
                    env.RUN_PACKAGE_STAGES = (
                        effectiveBranch == 'main' ||
                        effectiveBranch ==~ /^release\/.+/ ||
                        effectiveBranch ==~ /^hotfix\/.+/
                    ) ? 'true' : 'false'

                    currentBuild.displayName = "#${env.BUILD_NUMBER} ${env.EFFECTIVE_BRANCH_NAME}"
                    echo "Branch name: ${env.BRANCH_NAME ?: 'unset'}"
                    echo "Resolved branch: ${env.EFFECTIVE_BRANCH_NAME}"
                    echo "Image name: ${env.BRANCH_IMAGE_NAME}"
                    echo "Run package stages: ${env.RUN_PACKAGE_STAGES}"
                }
            }
        }

        stage('Prepare Static Workspace') {
            steps {
                sh '''
                    set -euo pipefail
                    rm -rf "${WORK_DIR}" "${BUILD_OUTPUT_DIR}" "${PACKAGE_SRC_DIR}" "${ARTIFACT_DIR}" "${IMAGE_DIR}" "${REPORT_DIR}"
                    mkdir -p "${WORK_DIR}" "${BUILD_OUTPUT_DIR}" "${ARTIFACT_DIR}" "${IMAGE_DIR}" "${JUNIT_DIR}" "${ALLURE_RESULTS_DIR}"
                '''
                stash name: 'python-source', includes: 'hello.py,requirements.txt,pytest.ini,tests/**', useDefaultExcludes: false
            }
        }

        stage('Build And Test On Kubernetes Agent') {
            agent {
                kubernetes {
                    defaultContainer 'python'
                    yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: python:3.12-slim
    command:
    - cat
    tty: true
'''
                }
            }
            environment {
                PYTHON_BIN = "python3"
                VENV_DIR = "${WORKSPACE}/.venv"
                WORK_DIR = "${WORKSPACE}/work"
                BUILD_OUTPUT_DIR = "${WORKSPACE}/build-output"
                PACKAGE_SRC_DIR = "${WORKSPACE}/package-src"
                REPORT_DIR = "${WORKSPACE}/reports"
                JUNIT_DIR = "${WORKSPACE}/reports/junit"
                ALLURE_RESULTS_DIR = "${WORKSPACE}/reports/allure-results"
            }
            steps {
                deleteDir()
                unstash 'python-source'
                sh '''
                    set -euo pipefail
                    rm -rf "${VENV_DIR}" "${WORK_DIR}" "${BUILD_OUTPUT_DIR}" "${PACKAGE_SRC_DIR}" "${REPORT_DIR}"
                    mkdir -p "${WORK_DIR}" "${BUILD_OUTPUT_DIR}" "${PACKAGE_SRC_DIR}" "${JUNIT_DIR}" "${ALLURE_RESULTS_DIR}"

                    "${PYTHON_BIN}" -m venv "${VENV_DIR}"
                    . "${VENV_DIR}/bin/activate"
                    python -m pip install --upgrade pip
                    python -m pip install -r requirements.txt

                    "${PYTHON_BIN}" hello.py | tee "${BUILD_OUTPUT_DIR}/hello-output.txt"
                    cp hello.py "${BUILD_OUTPUT_DIR}/hello.py"
                    cp hello.py "${PACKAGE_SRC_DIR}/hello.py"
                    python -m zipapp "${PACKAGE_SRC_DIR}" -m "hello:main" -o "${BUILD_OUTPUT_DIR}/hello-app.pyz"

                    pytest -v \
                      --junitxml="${JUNIT_DIR}/results.xml" \
                      --alluredir="${ALLURE_RESULTS_DIR}"

                    ls -lh "${BUILD_OUTPUT_DIR}"
                '''
                stash name: 'k8s-build-output', includes: 'build-output/**,reports/**', useDefaultExcludes: false
            }
        }

        stage('Collect Kubernetes Build Output') {
            steps {
                unstash 'k8s-build-output'
                sh '''
                    set -euo pipefail
                    tar -czf "${ARTIFACT_DIR}/hello-artifact.tar.gz" -C "${BUILD_OUTPUT_DIR}" .
                    ls -lh "${ARTIFACT_DIR}/hello-artifact.tar.gz"
                '''
            }
        }

        stage('Generate Allure HTML On Static Agent') {
            steps {
                sh '''
                    set -euo pipefail
                    if [ -x "${ALLURE_BIN}" ] && [ -d "${ALLURE_RESULTS_DIR}" ]; then
                        "${ALLURE_BIN}" generate "${ALLURE_RESULTS_DIR}" --clean -o "${ALLURE_HTML_DIR}"
                    fi
                '''
            }
        }

        stage('Build Podman Image On Static Agent') {
            when {
                expression { env.RUN_PACKAGE_STAGES == 'true' }
            }
            steps {
                sh '''
                    set -euo pipefail
                    IMAGE_ARCHIVE="${IMAGE_DIR}/${SAFE_BRANCH_NAME}-hello-artifact-image.tar"
                    if ! "${PODMAN_BIN}" info >/dev/null 2>&1; then
                        "${PODMAN_BIN}" machine start "${PODMAN_MACHINE}"
                    fi
                    "${PODMAN_BIN}" info >/dev/null
                    "${PODMAN_BIN}" build -t "${BRANCH_IMAGE_NAME}" -f Containerfile .
                    "${PODMAN_BIN}" save -o "${IMAGE_ARCHIVE}" "${BRANCH_IMAGE_NAME}"
                    printf '%s\n' "${BRANCH_IMAGE_NAME}" > "${IMAGE_DIR}/image-name.txt"
                    ls -lh "${IMAGE_ARCHIVE}" "${IMAGE_DIR}/image-name.txt"
                '''
            }
        }
    }

    post {
        always {
            script {
                if (fileExists('reports/junit/results.xml')) {
                    junit testResults: 'reports/junit/results.xml', allowEmptyResults: false
                }
            }
            archiveArtifacts artifacts: 'artifacts/*,images/*,reports/**/*,build-output/**/*', fingerprint: true, allowEmptyArchive: true
            script {
                if (fileExists('reports/allure-results')) {
                    try {
                        allure includeProperties: false, jdk: '', results: [[path: 'reports/allure-results']]
                    } catch (err) {
                        echo "Allure Jenkins plugin is not available. Raw results were archived from reports/allure-results."
                    }
                }
            }
        }
    }
}
