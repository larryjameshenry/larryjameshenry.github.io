# Research Dossier: Automating Security: A Practical Guide to DevSecOps Pipelines

This dossier compiles research for the article "Automating Security: A Practical Guide to DevSecOps Pipelines," covering the integration of SAST, DAST, SCA, and IaC scanning tools into CI/CD workflows.

## Section 1: The Layers of Automated Security

### 1.1 Code & Dependencies (SAST + SCA)

**Key Points:**
*   **SAST (Static Application Security Testing):** Analyzes source code for vulnerabilities without executing it. Tools: SonarQube, Semgrep, CodeQL.
*   **SCA (Software Composition Analysis):** Identifies known vulnerabilities in open-source dependencies (e.g., `npm` packages, `pip` libraries). Tools: OWASP Dependency-Check, Snyk, Trivy.
*   **Integration:** These should run in parallel with unit tests on every Pull Request.

### 1.2 Runtime & Infrastructure (DAST + IaC Scan)

**Key Points:**
*   **DAST (Dynamic Application Security Testing):** Tests the running application from the outside in (black-box testing). Tools: OWASP ZAP, Burp Suite.
*   **IaC Scanning:** Checks infrastructure code (Terraform, Kubernetes YAML) for misconfigurations like open S3 buckets or root containers. Tools: Checkov, Trivy, KICS.

**Content Elements:**
*   **Checkov Failed Output Example:**
    ```text
    Check: CKV_AWS_20: "S3 Bucket has an ACL defined which allows public access."
    FAILED for resource: aws_s3_bucket.example
    File: /main.tf:24-30
    Guide: https://docs.bridgecrew.io/docs/s3_1-s3-bucket-has-an-acl-defined-which-allows-public-access
    ```
*   **Trivy IaC Failed Output Example:**
    ```text
    Tests: 32 (SUCCESS: 31, FAIL: 1, EXCEPTION: 0)
    Failures:
      LOW: Dockerfile.user:24
      DS002: Image user:latest is not pinned to a specific version.
      See https://avd.aquasec.com/misconfig/ds002
    ```

## Section 2: Designing the Security Gate

### 2.2 Handling Secrets Management

**Key Points:**
*   **Risk:** Hardcoded credentials (API keys, passwords) in Git history are a critical vulnerability.
*   **Tool:** Gitleaks is the industry standard for detecting secrets.
*   **Configuration:** Use `.gitleaks.toml` to whitelist false positives.

**Content Elements:**
*   **Gitleaks Configuration (`.gitleaks.toml`):**
    ```toml
    [allowlist]
    description = "Global allowlist"
    regexes = [
        '''EXAMPLE_KEY_FOR_TESTING''', # Ignore specific testing keys
        '''mock-secret-value''',
    ]
    paths = [
        '''test/fixtures/.*''', # Ignore test data files
    ]
    ```

## Hands-On Example: Adding Trivy to GitHub Actions

**Scenario:** Integrating Aqua Security's Trivy scanner to scan both the repository filesystem (for config issues/secrets) and the built Docker image.

**Implementation Steps:**
1.  **Checkout:** Get the code.
2.  **Build:** Build the Docker image.
3.  **Scan FS:** Run Trivy on the filesystem.
4.  **Scan Image:** Run Trivy on the built image.
5.  **Upload:** Upload the results to GitHub Security tab (SARIF).

**Code Solution:**
*   **GitHub Actions Workflow (`.github/workflows/security.yml`):**

    ```yaml
    name: Security Scan
    on: [pull_request]

    jobs:
      trivy-scan:
        name: Trivy Security Scan
        runs-on: ubuntu-latest
        steps:
          - name: Checkout code
            uses: actions/checkout@v4

          - name: Build Docker Image
            run: docker build -t my-app:${{ github.sha }} .

          - name: Run Trivy vulnerability scanner (Filesystem)
            uses: aquasecurity/trivy-action@master
            with:
              scan-type: 'fs'
              scan-ref: '.'
              trivy-config: trivy.yaml
              format: 'table'
              exit-code: '1' # Fail if issues found
              severity: 'CRITICAL,HIGH'

          - name: Run Trivy vulnerability scanner (Image)
            uses: aquasecurity/trivy-action@master
            with:
              scan-type: 'image'
              image-ref: 'my-app:${{ github.sha }}'
              format: 'sarif'
              output: 'trivy-results.sarif'
              severity: 'CRITICAL,HIGH'

          - name: Upload Trivy scan results to GitHub Security tab
            uses: github/codeql-action/upload-sarif@v2
            if: always()
            with:
              sarif_file: 'trivy-results.sarif'
    ```

## Best Practices & Optimization

*   **Caching:** Cache vulnerability databases (e.g., Trivy DB) to speed up scans.
*   **Distroless Images:** Use `gcr.io/distroless` base images to reduce the OS attack surface and scan times (fewer packages to scan).
*   **Grace Periods:** Don't block on *new* zero-day vulnerabilities immediately; give teams 24-48h to patch.

## Troubleshooting Common Issues

### Issue 1: "Too Many False Positives"
*   **Solution:** Use a `.trivyignore` file to suppress specific CVEs that don't apply to your context or are being remediated.

**Content Elements:**
*   **`.trivyignore` Example:**
    ```text
    # Ignore CVE-2023-1234 because we don't use the vulnerable function
    CVE-2023-1234

    # Temporary ignore until patch is available (expiring rule)
    CVE-2024-5678 exp:2025-01-01
    ```
