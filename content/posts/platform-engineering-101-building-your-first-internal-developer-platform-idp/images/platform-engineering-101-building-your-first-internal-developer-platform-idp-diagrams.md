# Diagrams for "Platform Engineering 101: Building Your First Internal Developer Platform (IDP)"

## IDP Architecture: Portal, Orchestrator, Infrastructure

This diagram illustrates the core components of an Internal Developer Platform and how they interact to deliver self-service capabilities.

```mermaid
graph TD
    subgraph "Developer Experience Layer"
        User[Developer] -->|Interacts with| Portal[IDP Portal<br/>(Backstage/Port)]
        Portal -->|Displays| Catalog[Service Catalog]
        Portal -->|Offers| Templates[Golden Path Templates]
        Portal -->|Shows| Docs[TechDocs]
    end

    subgraph "Orchestration Layer (The Brain)"
        Portal -->|Triggers Action| Orchestrator[Platform Orchestrator<br/>(Humanitec/Kratix/Scripts)]
        Orchestrator -->|Commits Config| Git[Git Repository<br/>(GitOps Source of Truth)]
        Git -->|Syncs| CD[GitOps Controller<br/>(ArgoCD/Flux)]
    end

    subgraph "Infrastructure Layer (The Resources)"
        CD -->|Deploys to| K8s[Kubernetes Cluster]
        Orchestrator -->|Provisions via Terraform| Cloud[Cloud Resources<br/>(AWS/Azure Databases)]
    end

    classDef user fill:#f3e5f5,stroke:#4a148c,stroke-width:2px;
    classDef portal fill:#e1f5fe,stroke:#0277bd,stroke-width:2px;
    classDef logic fill:#fff3e0,stroke:#ff9800,stroke-width:2px;
    classDef infra fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;

    class User user;
    class Portal,Catalog,Templates,Docs portal;
    class Orchestrator,Git,CD logic;
    class K8s,Cloud infra;
```
