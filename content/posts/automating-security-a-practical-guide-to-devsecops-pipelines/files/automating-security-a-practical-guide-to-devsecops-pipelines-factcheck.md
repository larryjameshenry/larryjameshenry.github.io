# Fact-Check Report: Automating Security: A Practical Guide to DevSecOps Pipelines

This report verifies the technical claims, tool capabilities, and code accuracy in the "Automating Security" draft.

## 1. Tools and Technologies

*   **Trivy:**
    *   **Claim:** Can scan both filesystem (for config/secrets) and container images (for OS packages).
    *   **Verification:** **TRUE**. Trivy is a comprehensive security scanner that supports filesystem, image, repository, and SBOM scanning.
    *   **Claim:** `aquasecurity/trivy-action` is the correct GitHub Action.
    *   **Verification:** **TRUE**. This is the official action.

*   **Gitleaks:**
    *   **Claim:** Detects hardcoded secrets in Git history.
    *   **Verification:** **TRUE**. Gitleaks is designed specifically for this purpose.
    *   **Claim:** Uses a TOML configuration file (`.gitleaks.toml`) for allowlisting.
    *   **Verification:** **TRUE**. The configuration format and allowlist logic are correct.

*   **Checkov:**
    *   **Claim:** Scans IaC (Terraform, Kubernetes) for misconfigurations.
    *   **Verification:** **TRUE**. Checkov is a leading policy-as-code tool for IaC security.

*   **OWASP ZAP:**
    *   **Claim:** Performs DAST (Dynamic Application Security Testing).
    *   **Verification:** **TRUE**. ZAP is a widely used open-source DAST scanner.

## 2. Code Examples

*   **Checkov Output:**
    *   **Context:** Identifying a public S3 bucket (`CKV_AWS_20`).
    *   **Accuracy:** The error code `CKV_AWS_20` correctly corresponds to the "S3 Bucket has an ACL defined which allows public access" check in Checkov's database. The output format mimics a standard CLI result. **VERIFIED.**

*   **Gitleaks Configuration:**
    *   **Context:** Allowlisting specific secrets and paths.
    *   **Accuracy:** The TOML structure (`[allowlist]`, `regexes`, `paths`) matches the Gitleaks configuration schema. **VERIFIED.**

*   **GitHub Actions Workflow:**
    *   **Context:** Trivy scan setup.
    *   **Accuracy:**
        *   The workflow correctly builds the Docker image before scanning it.
        *   The `aquasecurity/trivy-action` inputs (`scan-type`, `image-ref`, `severity`) are correct.
        *   The use of `github/codeql-action/upload-sarif` is the standard way to integrate third-party security tools with GitHub Advanced Security. **VERIFIED.**

## 3. Concepts and Definitions

*   **SAST vs. DAST vs. SCA:** The definitions provided (Static analysis, Dynamic runtime analysis, and Dependency analysis) are accurate and distinct.
*   **"Shift Left":** Correctly defined as moving security checks earlier in the SDLC (e.g., to the PR or IDE stage).
*   **SARIF:** Correctly identified as the standard format for static analysis results integration.

## Conclusion

The article is factually accurate and uses correct tool configurations and terminology. No corrections are needed.
