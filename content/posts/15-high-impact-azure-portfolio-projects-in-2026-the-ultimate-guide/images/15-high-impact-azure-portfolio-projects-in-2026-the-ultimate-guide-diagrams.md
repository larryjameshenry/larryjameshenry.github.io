### Diagram Description
This diagram visualizes a highly available, multi-region web application architecture on Azure. It shows how user traffic is intelligently routed globally by Azure Front Door to backend web applications deployed in separate Azure regions, ensuring performance, resilience, and disaster recovery capabilities. The architecture includes global DNS resolution and geo-replication for the database tier.

### Mermaid Code
```mermaid
graph TD
    User(User) --> DNS[Azure DNS];
    DNS --> AFD[Azure Front Door (WAF, CDN, Traffic Manager)];

    subgraph Region 1 (e.g., East US)
        AFD -- HTTPS/HTTP --> A1[Azure App Service (Web App)];
        A1 --> KV1(Azure Key Vault);
        A1 --> DB1[Azure SQL Database / Cosmos DB];
    end

    subgraph Region 2 (e.g., West US)
        AFD -- HTTPS/HTTP --> A2[Azure App Service (Web App)];
        A2 --> KV2(Azure Key Vault);
        A2 --> DB2[Azure SQL Database / Cosmos DB];
    end

    DB1 -- Geo-Replication / Global Distribution --> DB2;
    KV1 -- Replication / Sync --> KV2;
    AFD -- Health Probes --> A1;
    AFD -- Health Probes --> A2;
```

### Visual Notes:
*   **User Flow:** Illustrates the path from an end-user through DNS and Azure Front Door to the closest healthy application backend.
*   **Regional Deployment:** Shows identical application stacks deployed in two distinct Azure regions for redundancy and proximity.
*   **Database Replication:** Represents the data synchronization mechanism between regional databases (e.g., SQL Geo-replication, Cosmos DB global distribution).
*   **Health Probes:** Azure Front Door continuously monitors the health of regional backends to ensure traffic is only sent to active instances.
*   **Key Vault Integration:** Each regional App Service connects to its respective Azure Key Vault for secure secret management.
*   **Simplified Abstraction:** For clarity, other Azure networking components (VNets, NSGs) are abstracted, focusing on the core multi-region application flow.
