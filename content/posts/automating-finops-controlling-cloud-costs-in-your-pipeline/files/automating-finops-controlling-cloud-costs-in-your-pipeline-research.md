# Research Dossier: Automating FinOps: Controlling Cloud Costs in Your Pipeline

This dossier compiles research for the article "Automating FinOps: Controlling Cloud Costs in Your Pipeline," covering Infracost integration, OPA policies, automated tagging, "Reaper" patterns, and best practices.

## Section 1: Shifting Cost Left

### 1.1 The "Price Check" Workflow (Infracost)

**Key Points:**
*   **Integration:** Infracost runs as a step in the CI/CD pipeline (GitHub Actions) to calculate cost differences for Terraform pull requests.
*   **API Key:** Requires an Infracost API key stored as a GitHub Secret (`INFRACOST_API_KEY`).
*   **Workflow Logic:**
    1.  Checkout code.
    2.  Setup Terraform and Infracost.
    3.  Run `infracost breakdown` to generate a JSON report.
    4.  Run `infracost comment` to post the diff to the PR.
*   **Alert Fatigue:** To avoid spamming developers with negligible cost changes, use the `percentage_threshold` or `diff_threshold` options, or filter comments to "update" existing ones rather than creating new ones.

**Content Elements:**
*   **GitHub Actions Workflow Snippet:**

    ```yaml
    name: Infracost
    on: [pull_request]
    jobs:
      infracost:
        runs-on: ubuntu-latest
        permissions:
          contents: read
          pull-requests: write
        steps:
          - uses: actions/checkout@v4
          - uses: hashicorp/setup-terraform@v3
          - uses: infracost/setup-infracost@v2
            with:
              api-key: ${{ secrets.INFRACOST_API_KEY }}

          - name: Generate Infracost cost estimate
            run: |
              infracost breakdown --path=. \
                                  --format=json \
                                  --out-file=/tmp/infracost.json

          - name: Post Infracost comment
            run: |
              infracost comment github --path=/tmp/infracost.json \
                                       --repo=$GITHUB_REPOSITORY \
                                       --github-token=${{ github.token }} \
                                       --pull-request=${{ github.event.pull_request.number }} \
                                       --behavior=update
    ```

### 1.2 Budget Guardrails (OPA)

**Key Points:**
*   **Open Policy Agent (OPA):** Use Rego policies to enforce hard limits on resource configurations.
*   **Policy Example:** Deny specific AWS EC2 instance types (e.g., prohibiting `x2gd.metal` or anything larger than `2xlarge`) to prevent accidental high-cost provisioning.
*   **Implementation:** OPA evaluates the Terraform plan JSON output against the Rego policy.

**Content Elements:**
*   **OPA Rego Policy (Deny Large Instances):**

    ```rego
    package terraform.aws.instance_type

    # List of allowed instance types (whitelist approach) or denied (blacklist)
    denied_types := {"x2gd.metal", "i3.16xlarge", "p4d.24xlarge"}

    deny[msg] {
      # Iterate over resource changes
      some i, resource_change in input.resource_changes
      resource_change.type == "aws_instance"
      
      # Check if creating or updating
      resource_change.change.actions[_] == "create"
      
      # Check instance type
      instance_type := resource_change.change.after.instance_type
      denied_types[instance_type]

      msg := sprintf("Instance type '%v' is too expensive/denied. Please use a smaller type.", [instance_type])
    }
    ```

## Section 2: Managing Infrastructure Lifecycle

### 2.1 The Tagging Strategy (Automated with Yor)

**Key Points:**
*   **Tagging is Critical:** Tags like `Owner`, `CostCenter`, and `TTL` are essential for cost allocation and automated cleanup.
*   **Automation Tool:** `bridgecrewio/yor` is an open-source tool that automatically adds tags to IaC templates (Terraform, CloudFormation, etc.) in CI/CD. It can add git-based tags (`git_last_modified_by`, `git_org`) which are perfect for "Owner" tracking.

**Content Elements:**
*   **Yor GitHub Action Snippet:**

    ```yaml
    - name: Run Yor tagger
      uses: bridgecrewio/yor-action@main
      with:
        directory: "."
        tag_groups: "git,code2cloud" # Automatically adds git user/repo tags
    ```

### 2.2 The "Reaper" Pattern (Cloud Custodian)

**Key Points:**
*   **Automated Cleanup:** Use Cloud Custodian policies to act on tags.
*   **Off-Hours:** Stop dev/test resources at night (e.g., 7 PM) and start them in the morning (e.g., 7 AM).
*   **TTL (Time To Live):** Terminate resources that have exceeded a specific age or expiration date tagged on them.

**Content Elements:**
*   **Cloud Custodian Off-Hours Policy:**

    ```yaml
    policies:
      - name: offhours-stop
        resource: aws.ec2
        filters:
          - type: offhour
            offhour: 19  # 7 PM
            default_tz: utc
            tag: c7n-offhours
        actions:
          - stop
    ```

*   **Cloud Custodian TTL Policy:**

    ```yaml
    policies:
      - name: ec2-ttl-terminator
        resource: aws.ec2
        filters:
          - "tag:TTL": present
          - type: value
            key: LaunchTime
            value_type: age
            op: gt
            value: 30 # Days
        actions:
          - terminate
    ```

## Best Practices & Optimization

*   **Gamification:**
    *   **Leaderboards:** Create a monthly leaderboard showing "Top Savers" (teams that reduced their bill the most).
    *   **"FinOps All-Star":** Recognize individuals who right-size the most resources.
    *   **Cleanup Hackathons:** Organize "Game Days" specifically focused on deleting unused resources.
*   **Spot Instances:**
    *   Use tools like **Karpenter** (for Kubernetes) or **AWS Auto Scaling Groups** to automatically leverage Spot instances for fault-tolerant workloads.
*   **Right-Sizing:**
    *   Use **AWS Compute Optimizer** or Kubernetes **VPA (Vertical Pod Autoscaler)** recommendations to automatically adjust resource requests/limits.

## Troubleshooting Common Issues

*   **"Infracost doesn't support my resource":**
    *   **Cause:** New services or niche resources might not be in the Infracost pricing database yet.
    *   **Solution:** Use the usage file to estimate costs manually or check the Infracost GitHub issues for updates.
*   **"Developers ignore cost comments":**
    *   **Cause:** Alert fatigue from seeing "$0.01 change" comments.
    *   **Solution:** Configure Infracost to only comment if the monthly cost difference is > $50 (`--diff-threshold=50`).
