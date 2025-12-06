# Diagrams for "The Ultimate Guide to DevOps Automation in 2025"

## Traditional Ops vs. Platform Engineering

This diagram illustrates the fundamental shift from a ticket-based, high-friction model to a self-service, API-driven platform model.

```mermaid
graph TD
    subgraph "Traditional DevOps (Ops as a Service)"
        Dev1[Developer Team] -->|Ticket/Jira| Ops[Ops Team]
        Ops -->|Manual Provisioning| Cloud1[Cloud Infrastructure]
        Ops -.->|Bottleneck| Dev1
    end

    subgraph "Platform Engineering (Platform as a Product)"
        Dev2[Stream-Aligned Team] -->|API / Portal| IDP[Internal Developer Platform]
        IDP -->|Automated Provisioning| Cloud2[Cloud Infrastructure]
        PlatformTeam[Platform Team] -->|Builds & Maintains| IDP
    end

    classDef team fill:#e3f2fd,stroke:#1565c0,stroke-width:2px;
    classDef infra fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
    classDef system fill:#fff3e0,stroke:#ff9800,stroke-width:2px;

    class Dev1,Ops,Dev2,PlatformTeam team;
    class Cloud1,Cloud2 infra;
    class IDP system;
```
