# Diagrams for "GitOps at Scale: Managing Multi-Cluster Kubernetes with ArgoCD"

## The GitOps Workflow: Commit, Reconcile, Deploy

This diagram illustrates the continuous reconciliation loop that is the core of the GitOps operating model.

```mermaid
graph LR
    subgraph "Source of Truth (Git)"
        A[Developer / Automation] -->|git commit & push| B(Git Repository<br/>Desired State)
    end

    subgraph "GitOps Controller (ArgoCD)"
        B -.->|Polls/Webhooks| C[ArgoCD Application Controller]
        C -->|Compares State| D{Drift Detected?}
    end

    subgraph "Target Infrastructure (Kubernetes)"
        D -->|Yes: Reconcile| E[Apply Manifests<br/>kubectl apply]
        D -->|No: No-Op| F[Healthy State]
        E --> G(Live Cluster<br/>Actual State)
    end

    G -.->|Reports Status| C
    
    classDef git fill:#f3e5f5,stroke:#2e7d32,stroke-width:2px;
    classDef controller fill:#e1f5fe,stroke:#0277bd,stroke-width:2px;
    classDef cluster fill:#fff3e0,stroke:#ff9800,stroke-width:2px;
    
    class A,B git;
    class C,D controller;
    class E,F,G cluster;
```
