# Jenkins Python Podman Hello

This project demonstrates a hybrid Jenkins pipeline flow:

1. Check out a Git repo containing `hello.py`
2. Run the Python build and tests on a Kubernetes cloud agent
3. Produce a build output folder containing the runnable Python bundle and execution output
4. Transfer that build output back to the static Jenkins agent
5. Generate JUnit and Allure reports
6. Package the build output as a local artifact
7. Build a Podman image on the static agent from the downloaded build output
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

- `build-output/hello.py`
- `build-output/hello-output.txt`
- `build-output/hello-app.pyz`
- `artifacts/hello-artifact.tar.gz`
- `images/hello-artifact-image.tar`
- `reports/junit/results.xml`
- `reports/allure-results/`
- `reports/allure-html/index.html` when the Allure CLI is available on the static agent

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

The active pipeline files are hybrid:

- `Jenkinsfile` runs the build and tests on a Kubernetes agent, then hands the build output to the static agent for Podman packaging
- `Jenkinsfile.verify` runs verification on a Kubernetes agent and generates reports on the static agent
- `Jenkinsfile.image` creates the build output on a Kubernetes agent and builds the image on the static agent
- `Jenkinsfile` resolves the branch name from Jenkins multibranch metadata or Git checkout metadata so regular Pipeline jobs still package on `main`

These pipelines require:

- a configured Kubernetes cloud in `Manage Jenkins -> Clouds`
- outbound network access from the Kubernetes build pod
- a static Jenkins agent with local Python, Podman, and Allure CLI

## How to verify the pipeline

The pipeline is healthy when all of these are true:

- Jenkins build status is `SUCCESS`
- Stage view shows `Run Script On Agent`, `Verify Script And Generate Test Reports`, `Create Artifact`, and `Build Podman Image` as green
- Jenkins test result shows 2 passing tests
- `reports/junit/results.xml` exists
- `reports/allure-results/` exists and the Jenkins Allure plugin publishes the report tab if installed
- `reports/allure-html/index.html` exists when the static agent has the Allure CLI
- `artifacts/hello-artifact.tar.gz` exists
- `images/hello-artifact-image.tar` exists

## Recommended Jenkins jobs

- Use `Jenkinsfile.verify` first to confirm the Kubernetes build/test stage and report publishing
- Use `Jenkinsfile.image` next to verify Kubernetes build output handoff and static-agent Podman image creation
- Use `Jenkinsfile` when you want the full end-to-end hybrid flow in one run

## Multibranch pipeline behavior

Use `Jenkinsfile` as the script path in a Jenkins Multibranch Pipeline job.

- All branches run checkout, Kubernetes build, pytest, JUnit publishing, and Allure reporting
- Only `main`, `release/*`, and `hotfix/*` branches run `Create Artifact` and `Build Podman Image On Static Agent`
- Pull request branches and feature branches skip the image packaging stages
- Saved image archives are branch-specific, for example `images/main-hello-artifact-image.tar`

## Jenkins multibranch setup

1. Create a `Multibranch Pipeline` job in Jenkins
2. Add your GitHub repository as the branch source
3. Keep the script path as `Jenkinsfile`
4. Enable branch discovery and pull request discovery
5. Run `Scan Multibranch Pipeline Now`

## Kubernetes cloud-agent setup

Configure a Kubernetes cloud in `Manage Jenkins -> Clouds` before running these pipelines. The build and test stages use that cloud, while the Podman image build stays on the static agent.
