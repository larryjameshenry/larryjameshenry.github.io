# Diagrams for "Automating Security: A Practical Guide to DevSecOps Pipelines"

## The Secure Supply Chain Pipeline

This diagram illustrates the integration of automated security checks at each stage of the CI/CD pipeline, demonstrating the "Shift Left" approach.

```mermaid
graph TD
    subgraph "Code & Commit (Shift Left)"
        A[Developer] -->|Commit| B(Git Repository)
        A -.->|Pre-commit Hook<br/>(Gitleaks)| A
    end

    subgraph "Continuous Integration (CI)"
        B --> C{Build Pipeline}
        C -->|Parallel| D[SAST Scan<br/>(Semgrep/SonarQube)]
        C -->|Parallel| E[SCA Scan<br/>(Snyk/Dependency-Check)]
        C -->|Parallel| F[Secret Detection<br/>(TruffleHog)]
        
        D --> G{Security Gate}
        E --> G
        F --> G
        
        G -->|Pass| H[Build Artifact<br/>(Docker Image)]
        G -->|Fail| I[Block Build & Alert]
    end

    subgraph "Artifact & Deployment"
        H --> J[Container Registry]
        J --> K[Image Scan<br/>(Trivy)]
        K --> L{Deployment Gate}
        
        L -->|Pass| M[IaC Scan<br/>(Checkov/Terraform)]
        M --> N[Deploy to Staging]
    end

    subgraph "Runtime (DAST)"
        N --> O[DAST Scan<br/>(OWASP ZAP)]
        O --> P{Runtime Gate}
        P -->|Pass| Q[Promote to Production]
    end

    classDef default fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef secure fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
    classDef fail fill:#ffebee,stroke:#c62828,stroke-width:2px;
    
    class D,E,F,K,M,O secure;
    class I fail;
```
