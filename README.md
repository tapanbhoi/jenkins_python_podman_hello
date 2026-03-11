# Jenkins Python Podman Hello

This project demonstrates a simple Jenkins pipeline flow:

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
- `reports/allure-html/index.html`

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

Create a Jenkins Pipeline job and point it at this Git repo. Jenkins will run the `Jenkinsfile` automatically.

If Podman is not already running on macOS, the local script and the Jenkins pipeline both attempt `podman machine start` before building the image.

## How to verify the pipeline

The pipeline is healthy when all of these are true:

- Jenkins build status is `SUCCESS`
- Stage view shows `Run Script On Agent`, `Verify Script And Generate Test Reports`, `Create Artifact`, and `Build Podman Image` as green
- Jenkins test result shows 2 passing tests
- `reports/junit/results.xml` exists
- `reports/allure-html/index.html` exists or the Jenkins Allure plugin publishes the report tab
- `artifacts/hello-artifact.tar.gz` exists
- `images/hello-artifact-image.tar` exists

## Recommended Jenkins jobs

- Use `Jenkinsfile.verify` first to confirm checkout, script execution, test pass rate, JUnit publishing, and Allure reporting
- Use `Jenkinsfile.image` next to verify artifact packaging and Podman image creation separately
- Use `Jenkinsfile` only when you want the full end-to-end flow in one run
