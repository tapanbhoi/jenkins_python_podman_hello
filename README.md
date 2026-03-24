# Jenkins Python Podman Hello

This project demonstrates a simple Jenkins pipeline flow on a local Jenkins static agent, with optional Kubernetes cloud-agent variants:

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
- `Jenkinsfile.k8s`: full pipeline for Jenkins Kubernetes cloud agents
- `Jenkinsfile.verify.k8s`: verification-only pipeline for Kubernetes cloud agents
- `Jenkinsfile.image.k8s`: artifact and image pipeline for Kubernetes cloud agents
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

The default Jenkins pipeline files are written for a local static Jenkins agent:

- `Jenkinsfile`, `Jenkinsfile.verify`, and `Jenkinsfile.image` run on `agent any`
- They use the locally installed Python, Podman, and Allure CLI on this Mac
- `Jenkinsfile` resolves the branch name from Jenkins multibranch metadata or Git checkout metadata so regular Pipeline jobs still package on `main`

Use the `.k8s` variants only after a Kubernetes cloud is configured in Jenkins:

- `Jenkinsfile.k8s`
- `Jenkinsfile.verify.k8s`
- `Jenkinsfile.image.k8s`

The `.k8s` pipelines require:

- a configured Kubernetes cloud in `Manage Jenkins -> Clouds`
- a cluster policy that allows privileged Podman containers
- outbound network access from the build pod

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

## Kubernetes cloud-agent setup

If you want Jenkins to run in Kubernetes pods later, configure a Kubernetes cloud first and then switch the Jenkins job script path to one of the `.k8s` files.
