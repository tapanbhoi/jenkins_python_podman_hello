pipeline {
    agent {
        kubernetes {
            defaultContainer 'python'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsUser: 0
  containers:
  - name: python
    image: python:3.12-slim
    command:
    - cat
    tty: true
  - name: podman
    image: quay.io/podman/stable:latest
    command:
    - cat
    tty: true
    securityContext:
      privileged: true
      runAsUser: 0
    volumeMounts:
    - name: containers-storage
      mountPath: /var/lib/containers
    - name: tmp-storage
      mountPath: /tmp
  volumes:
  - name: containers-storage
    emptyDir: {}
  - name: tmp-storage
    emptyDir: {}
'''
        }
    }

    options {
        skipDefaultCheckout(true)
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        PYTHON_BIN = "python3"
        PODMAN_BIN = "podman"
        STORAGE_DRIVER = "vfs"
        VENV_DIR = "${WORKSPACE}/.venv"
        WORK_DIR = "${WORKSPACE}/work"
        ARTIFACT_CONTENT_DIR = "${WORKSPACE}/artifact-content"
        ARTIFACT_DIR = "${WORKSPACE}/artifacts"
        IMAGE_DIR = "${WORKSPACE}/images"
        REPORT_DIR = "${WORKSPACE}/reports"
        JUNIT_DIR = "${WORKSPACE}/reports/junit"
        ALLURE_RESULTS_DIR = "${WORKSPACE}/reports/allure-results"
        IMAGE_REPO = "local/hello-artifact"
    }

    stages {
        stage('Checkout') {
            steps {
                container('python') {
                    sh '''
                        set -euo pipefail
                        apt-get update
                        apt-get install -y git
                    '''
                    checkout scm
                }
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
                    echo "Change request: ${env.CHANGE_ID ?: 'no'}"
                    echo "Image name: ${env.BRANCH_IMAGE_NAME}"
                    echo "Run package stages: ${env.RUN_PACKAGE_STAGES}"
                }
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
                '''
            }
        }

        stage('Create Artifact') {
            when {
                expression { env.RUN_PACKAGE_STAGES == 'true' }
            }
            steps {
                sh '''
                    set -euo pipefail
                    tar -czf "${ARTIFACT_DIR}/hello-artifact.tar.gz" -C "${ARTIFACT_CONTENT_DIR}" .
                    ls -lh "${ARTIFACT_DIR}/hello-artifact.tar.gz"
                '''
            }
        }

        stage('Build Podman Image') {
            when {
                expression { env.RUN_PACKAGE_STAGES == 'true' }
            }
            steps {
                container('podman') {
                    sh '''
                        set -euo pipefail
                        IMAGE_ARCHIVE="${IMAGE_DIR}/${SAFE_BRANCH_NAME}-hello-artifact-image.tar"
                        "${PODMAN_BIN}" info >/dev/null
                        "${PODMAN_BIN}" --storage-driver="${STORAGE_DRIVER}" build -t "${BRANCH_IMAGE_NAME}" -f Containerfile .
                        "${PODMAN_BIN}" --storage-driver="${STORAGE_DRIVER}" save -o "${IMAGE_ARCHIVE}" "${BRANCH_IMAGE_NAME}"
                        printf '%s\n' "${BRANCH_IMAGE_NAME}" > "${IMAGE_DIR}/image-name.txt"
                        ls -lh "${IMAGE_ARCHIVE}" "${IMAGE_DIR}/image-name.txt"
                    '''
                }
            }
        }
    }

    post {
        always {
            junit testResults: 'reports/junit/results.xml', allowEmptyResults: false
            archiveArtifacts artifacts: 'artifacts/*,images/*,reports/**/*,artifact-content/*', fingerprint: true, allowEmptyArchive: true
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
