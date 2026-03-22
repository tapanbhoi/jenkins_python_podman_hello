# Jenkins Python Podman Hello

This project demonstrates a simple Jenkins pipeline flow on Jenkins Kubernetes cloud agents:

1. Check out a Git repo containing `hello.py`
2. Copy the script into the Jenkins agent workspace
3. Run the script on the agent
4. Run automated verification with `pytest`
5. Generate JUnit and Allure reports
6. Create a local artifact from the script and its output
7. Build a Podman image from that generated artifact content
8. Save the image as a local tar file in the project directory

## Files

- `hello.py`: simple Python hello world script
- `Jenkinsfile`: declarative pipeline for Jenkins
- `Jenkinsfile.verify`: verification-only pipeline for script execution and reports
- `Jenkinsfile.image`: artifact and Podman image pipeline
- `Containerfile`: image definition that packages the generated artifact content
- `scripts/run_local_flow.sh`: local equivalent of the Jenkins stages
- `scripts/run_verify_flow.sh`: local equivalent of the verification pipeline
- `scripts/run_image_flow.sh`: local equivalent of the image pipeline
- `tests/test_hello.py`: automated checks for the function and script execution
- `requirements.txt`: Python test dependencies

## Generated output

After a successful run, Jenkins or the local script creates:

- `artifact-content/hello.py`
- `artifact-content/hello-output.txt`
- `artifacts/hello-artifact.tar.gz`
- `images/hello-artifact-image.tar`
- `reports/junit/results.xml`
- `reports/allure-results/`

## Run locally

```bash
cd /Users/tapanbhoi/Documents/Container/jenkins_python_podman_hello
chmod +x scripts/run_local_flow.sh
./scripts/run_local_flow.sh
```

## Run verification only

```bash
cd /Users/tapanbhoi/Documents/Container/jenkins_python_podman_hello
chmod +x scripts/run_verify_flow.sh
./scripts/run_verify_flow.sh
```

## Run image build only

```bash
cd /Users/tapanbhoi/Documents/Container/jenkins_python_podman_hello
chmod +x scripts/run_image_flow.sh
./scripts/run_image_flow.sh
```

## Jenkins pipeline setup

Create a Jenkins Pipeline or Multibranch Pipeline job and point it at this Git repo. Jenkins will run the `Jenkinsfile` automatically.

The Jenkins pipeline files are written for Kubernetes cloud agents instead of static nodes:

- `Jenkinsfile` uses a Kubernetes pod with `python` and `podman` containers
- `Jenkinsfile.verify` uses a Kubernetes pod with a `python` container
- `Jenkinsfile.image` uses a Kubernetes pod with `python` and `podman` containers
- The pods run as root so the `python` container can install `git` before `checkout scm`
- Podman image build steps run inside the `podman` container with the `vfs` storage driver
- The podman container is configured as `privileged` and mounts `emptyDir` volumes for `/var/lib/containers` and `/tmp`
- Allure raw results are archived and published through the Jenkins Allure plugin if it is installed
- `Jenkinsfile` resolves the branch name from Jenkins multibranch metadata or Git checkout metadata so regular Pipeline jobs still package on `main`

## How to verify the pipeline

The pipeline is healthy when all of these are true:

- Jenkins build status is `SUCCESS`
- Stage view shows `Run Script On Agent`, `Verify Script And Generate Test Reports`, `Create Artifact`, and `Build Podman Image` as green
- Jenkins test result shows 2 passing tests
- `reports/junit/results.xml` exists
- `reports/allure-results/` exists and the Jenkins Allure plugin publishes the report tab if installed
- `artifacts/hello-artifact.tar.gz` exists
- `images/hello-artifact-image.tar` exists

## Recommended Jenkins jobs

- Use `Jenkinsfile.verify` first to confirm checkout, script execution, test pass rate, JUnit publishing, and Allure reporting
- Use `Jenkinsfile.image` next to verify artifact packaging and Podman image creation separately
- Use `Jenkinsfile` only when you want the full end-to-end flow in one run

## Multibranch pipeline behavior

Use `Jenkinsfile` as the script path in a Jenkins Multibranch Pipeline job.

- All branches run checkout, script execution, pytest, JUnit publishing, and Allure reporting
- Only `main`, `release/*`, and `hotfix/*` branches run `Create Artifact` and `Build Podman Image`
- Pull request branches and feature branches skip the image packaging stages
- Saved image archives are branch-specific, for example `images/main-hello-artifact-image.tar`

## Jenkins multibranch setup

1. Create a `Multibranch Pipeline` job in Jenkins
2. Add your GitHub repository as the branch source
3. Keep the script path as `Jenkinsfile`
4. Enable branch discovery and pull request discovery
5. Run `Scan Multibranch Pipeline Now`
