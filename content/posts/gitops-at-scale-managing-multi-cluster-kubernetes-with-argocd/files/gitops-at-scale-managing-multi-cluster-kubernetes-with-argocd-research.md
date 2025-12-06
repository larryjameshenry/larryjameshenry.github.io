# Research Dossier: GitOps at Scale: Managing Multi-Cluster Kubernetes with ArgoCD

This dossier compiles research for the article "GitOps at Scale," covering architectural patterns, ApplicationSets, directory structures, secrets management, and troubleshooting for multi-cluster ArgoCD environments.

## Section 1: The GitOps Architecture

### 1.2 The "App of Apps" Pattern

**Key Points:**
*   **Concept:** A "Root Application" in ArgoCD that manages other ArgoCD "Child Applications."
*   **Benefit:** Enables one-click bootstrap of a new cluster with a defined set of apps.
*   **Self-Management:** The root app can even manage itself if the `path` points to its own manifest.

**Content Elements:**
*   **Directory Tree Structure:**
    ```text
    .
    ├── argocd/
    │   ├── root-app.yaml                 # The Master App
    │   └── applications/                 # Child Apps definitions
    │       ├── guestbook.yaml
    │       ├── prometheus.yaml
    │       └── sealed-secrets.yaml
    └── manifests/
        ├── guestbook/                    # Actual K8s manifests
        └── ...
    ```

*   **Root App Manifest (`argocd/root-app.yaml`):**
    ```yaml
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: root-app
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/my-org/gitops-repo.git
        targetRevision: HEAD
        path: argocd/applications  # Points to folder containing child apps
      destination:
        server: https://kubernetes.default.svc
        namespace: argocd
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
    ```

## Section 2: Scaling with ApplicationSets

### 2.1 Generators: Dynamic Targeting

**Key Points:**
*   **Cluster Generator:** Automatically discovers clusters registered in ArgoCD based on labels.
*   **Dynamic Templating:** Uses `{{name}}` and `{{server}}` variables to configure the child applications dynamically.

**Content Elements:**
*   **ApplicationSet YAML (Cluster Generator):**
    ```yaml
    apiVersion: argoproj.io/v1alpha1
    kind: ApplicationSet
    metadata:
      name: guestbook
      namespace: argocd
    spec:
      generators:
      - clusters:
          selector:
            matchLabels:
              env: prod  # Only target clusters labeled 'env=prod'
      template:
        metadata:
          name: '{{name}}-guestbook'
        spec:
          project: default
          source:
            repoURL: https://github.com/argoproj/argocd-example-apps.git
            targetRevision: HEAD
            path: guestbook
          destination:
            server: '{{server}}'
            namespace: guestbook
    ```

*   **CLI Command to Label Clusters:**
    ```bash
    # Syntax: argocd cluster add <CONTEXT> --label <KEY>=<VALUE>
    argocd cluster add my-dev-cluster --label env=dev
    argocd cluster add my-prod-cluster --label env=prod
    ```

### 2.2 Directory Structure Strategy (Kustomize)

**Key Points:**
*   **Base/Overlay Pattern:** Define shared config in `base`, and environment specifics in `overlays`.
*   **Don't Duplicate:** Avoid copy-pasting YAML. Use patches.

**Content Elements:**
*   **Kustomize Tree Structure:**
    ```text
    .
    ├── base/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── kustomization.yaml
    └── overlays/
        ├── dev/
        │   ├── kustomization.yaml
        │   ├── replicas-patch.yaml    # Sets replicas: 1
        │   └── map-dev.yaml
        └── prod/
            ├── kustomization.yaml
            ├── replicas-patch.yaml    # Sets replicas: 3
            └── map-prod.yaml
    ```

## Secrets Management

**External Secrets Operator (ESO) vs. Sealed Secrets:**
*   **Sealed Secrets:**
    *   *Pros:* Simple, Git-native (encrypted in repo).
    *   *Cons:* Static. Harder to manage key rotation across many clusters.
*   **External Secrets Operator (ESO):**
    *   *Pros:* Dynamic. Fetches from AWS Secrets Manager/Vault. Centralized control.
    *   *Cons:* Requires setup of external provider.
    *   *Verdict:* **ESO** is preferred for "GitOps at Scale" to avoid managing hundreds of encrypted files in Git.

## Troubleshooting Common Issues

**Issue 1: "Application is OutOfSync but diff is empty"**
*   **Solution:** Use `ignoreDifferences` in the Application manifest to ignore fields modified by admission controllers (e.g., mutating webhooks like Istio or Linkerd).

**Content Elements:**
*   **`ignoreDifferences` YAML:**
    ```yaml
    spec:
      ignoreDifferences:
      - group: apps
        kind: Deployment
        jsonPointers:
        - /spec/replicas  # Ignored because HPA manages it
      - group: ""
        kind: Secret
        jsonPointers:
        - /data/token     # Ignored because it's dynamic
    ```
