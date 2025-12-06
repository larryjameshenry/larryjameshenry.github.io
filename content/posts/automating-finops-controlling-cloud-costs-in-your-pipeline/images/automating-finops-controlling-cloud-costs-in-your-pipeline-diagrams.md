# Diagrams for "Automating FinOps: Controlling Cloud Costs in Your Pipeline"

## The "Reaper" Pattern: Automated Lifecycle Management

This diagram illustrates how a "Reaper" automation (like Cloud Custodian) enforces cost control by shutting down or terminating resources based on tags and schedules.

```mermaid
graph TD
    subgraph "Cloud Environment (AWS/Azure)"
        R1[EC2 Instance<br/>Tag: Env=Dev<br/>Tag: TTL=2025-12-31]
        R2[RDS Database<br/>Tag: Env=Prod]
        R3[EKS Cluster<br/>Tag: Env=Test<br/>Tag: OffHours=True]
    end

    subgraph "Automation (The Reaper)"
        S[Scheduler / Cron Job<br/>(Every Hour)] --> P{Policy Engine<br/>(Cloud Custodian)}
        
        P -- "Check Tags & Time" --> R1
        P -- "Check Tags & Time" --> R2
        P -- "Check Tags & Time" --> R3
    end

    subgraph "Actions"
        A1[Stop Instance]
        A2[Terminate Resource]
        A3[No Action]
    end

    %% Logic Flow
    P -->|TTL Expired?| D1{Yes}
    D1 -->|Terminate| A2
    A2 -.->|Delete| R1

    P -->|Off-Hours Window?| D2{Yes}
    D2 -->|Has OffHours Tag?| D3{Yes}
    D3 -->|Stop| A1
    A1 -.->|Shutdown| R3

    P -->|Prod Environment?| A3
    A3 -.->|Ignore| R2

    classDef resource fill:#e1f5fe,stroke:#0277bd,stroke-width:2px;
    classDef engine fill:#fff3e0,stroke:#ff9800,stroke-width:2px;
    classDef action fill:#ffebee,stroke:#c62828,stroke-width:2px;
    
    class R1,R2,R3 resource;
    class S,P engine;
    class A1,A2,A3 action;
```
