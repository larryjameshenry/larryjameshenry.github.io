# Fact-Check Report: Automating FinOps: Controlling Cloud Costs in Your Pipeline

This report verifies the technical claims, tool capabilities, and code accuracy in the "Automating FinOps" draft.

## 1. Tools and Technologies

*   **Infracost:**
    *   **Claim:** Integrates with CI/CD (GitHub Actions) to show cost diffs in PRs.
    *   **Verification:** **TRUE**. Infracost is widely known for this functionality and provides official GitHub Actions.
    *   **Claim:** Supports "Budget Breakers" or stopping deployments based on cost.
    *   **Verification:** **TRUE**. Infracost allows setting policies (e.g., via OPA or its own config) to fail CI checks if cost thresholds are exceeded.
    *   **Claim:** Has a VS Code extension.
    *   **Verification:** **TRUE**. The extension provides real-time cost estimates in the editor.

*   **Open Policy Agent (OPA):**
    *   **Claim:** Can be used to deny specific AWS instance types.
    *   **Verification:** **TRUE**. OPA Rego policies can parse Terraform plans (converted to JSON) and enforce arbitrary rules, including instance type restrictions.

*   **Yor (bridgecrewio/yor):**
    *   **Claim:** Automatically adds tags like `git_last_modified_by` to IaC templates.
    *   **Verification:** **TRUE**. Yor is designed specifically for automated tagging of IaC resources with git context.

*   **Cloud Custodian:**
    *   **Claim:** Can automate "Lights Out" (stop/start) and "TTL" (terminate) actions based on tags.
    *   **Verification:** **TRUE**. Cloud Custodian is the industry standard open-source tool for this type of policy-based cloud governance.

## 2. Code Examples

*   **OPA Rego Policy:**
    *   **Context:** Denying `aws_instance` types `x2gd.metal`, etc.
    *   **Accuracy:** The Rego syntax is correct for analyzing a Terraform plan JSON structure (iterating over `input.resource_changes`). The logic checks for `create` actions and validates `instance_type`. **VERIFIED.**

*   **GitHub Actions Workflow:**
    *   **Context:** Infracost setup.
    *   **Accuracy:** The workflow uses official actions `infracost/setup-infracost` and `infracost/actions/comment`. The arguments (`api-key`, `path`, `behavior`, `diff-threshold`) are correct according to Infracost documentation. **VERIFIED.**

## 3. Concepts and Definitions

*   **"Shift Left" FinOps:** Accurately described as moving cost visibility to the Pull Request stage (before deployment).
*   **Feedback Gap:** Correctly identifies the delay between provisioning and billing as a root cause of waste.
*   **TTL (Time To Live):** Correctly defined as a mechanism to expire ephemeral resources.

## 4. Outdated Information Check

*   **Terraform Version:** The example uses `terraform_version: 1.5.0`. This is a reasonably recent and stable version (current stable is 1.9.x as of late 2024/early 2025), so it's safe for a guide.
*   **Action Versions:** `actions/checkout@v4` and `hashicorp/setup-terraform@v3` are the current major versions.

## Conclusion

The article is factually accurate and uses up-to-date tools and practices. No corrections are needed.
