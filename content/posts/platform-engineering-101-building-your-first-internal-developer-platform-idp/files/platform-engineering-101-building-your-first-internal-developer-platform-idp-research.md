# Research Dossier: Platform Engineering 101: Building Your First Internal Developer Platform (IDP)

This dossier compiles research for the article "Platform Engineering 101," covering core concepts, tool comparisons, and a hands-on guide to building a Backstage portal.

## Section 1: What is Platform Engineering?

### 1.1 Definitions & Concepts

**Internal Developer Platform (IDP):**
A curated set of tools, services, and technologies glued together by a dedicated product team to lower cognitive load for developers. It enables self-service for common tasks (provisioning, deployment, monitoring) without abstracting away useful context.

**The "Team Topologies" Connection:**
*   **Stream-aligned teams:** The "customers" of the platform. They deliver value to end-users.
*   **Platform teams:** Their goal is to reduce the cognitive load of stream-aligned teams.
*   **Quote:** "The purpose of a platform team is to enable stream-aligned teams to deliver work with substantial autonomy." — Matthew Skelton

**Cognitive Load:**
The amount of mental effort required to understand and use the underlying infrastructure. Platform Engineering aims to reduce "extraneous" cognitive load (e.g., how to configure a VPC) so devs can focus on "germane" load (e.g., business logic).

### 1.2 Core Components (Architecture)

1.  **Portal (Interface):** The "front door" (e.g., Backstage).
2.  **Orchestrator (Brain):** The API that executes requests (e.g., Humanitec, ArgoCD, Custom Scripts).
3.  **Infrastructure (Resource):** The actual cloud resources (AWS, K8s).

## Section 2: Designing Your "Golden Path"

**Golden Path (Paved Road):**
An opinionated, supported way of doing things. If a developer follows the Golden Path, the platform team guarantees support and SLA.
*   **Example:** A "Spring Boot on K8s" template that comes with pre-wired CI/CD, logging, and security scanning.

**Thinnest Viable Platform (TVP):**
Avoid building a massive "Death Star" platform on day one. Start with a simple CLI or a single documentation page. Solve the *loudest* complaint first.

## Section 3: Choosing Your Tool Stack

### 3.1 Comparison: Backstage vs. Port vs. Compass

| Feature | **Backstage** | **Port** | **Atlassian Compass** |
| :--- | :--- | :--- | :--- |
| **Type** | Open Source Framework | SaaS Product | SaaS Product |
| **Cost** | Free (High Engineering Cost) | Paid (Per user/service) | Paid (Free tier available) |
| **Customization** | Unlimited (Code-first) | High (No-code/Low-code) | Medium (Opinionated) |
| **Maintenance** | High (You build & host it) | Low (Managed) | Low (Managed) |
| **Best For** | Engineering-heavy orgs needing total control | Teams wanting speed & low maintenance | Atlassian-heavy shops |

## Hands-On Example: Scaffolding with Backstage

### 4.1 Setup

**Command:**
```bash
npx @backstage/create-app@latest
# Follow the prompts to name your app
cd my-backstage-app
yarn dev
```

### 4.2 The Template (`template.yaml`)

This YAML defines a "Golden Path" for creating a Node.js service.

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: nodejs-service
  title: Node.js Service
  description: Create a production-ready Node.js service
  tags: ['nodejs', 'recommended']
spec:
  owner: platform-team
  type: service

  # 1. Input Form
  parameters:
    - title: Service Details
      required: ['name', 'owner']
      properties:
        name:
          title: Name
          type: string
          description: Unique name of the service
          ui:autofocus: true
        owner:
          title: Owner
          type: string
          description: Owner of the component
          ui:field: OwnerPicker
          ui:options:
            allowedKinds: ['Group']

    - title: Repository
      required: ['repoUrl']
      properties:
        repoUrl:
          title: Repository Location
          type: string
          ui:field: RepoUrlPicker
          ui:options:
            allowedHosts: ['github.com']

  # 2. Execution Steps
  steps:
    - id: fetch-base
      name: Fetch Base Template
      action: fetch:template
      input:
        url: ./template # Path to your skeleton code
        values:
          name: ${{ parameters.name }}
          owner: ${{ parameters.owner }}

    - id: publish
      name: Publish to GitHub
      action: publish:github
      input:
        allowedHosts: ['github.com']
        description: ${{ parameters.name }}
        repoUrl: ${{ parameters.repoUrl }}
        defaultBranch: main

    - id: register
      name: Register in Catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: '/catalog-info.yaml'

  # 3. Output
  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}
      - title: Open in Catalog
        icon: catalog
        entityRef: ${{ steps.register.output.entityRef }}
```

## Best Practices & Troubleshooting

### Do's
*   **Treat Platform as Product:** measure adoption, satisfaction (NPS), and usage.
*   **Documentation:** "Docs-like-code" (TechDocs) is essential.

### Don'ts
*   **Mandate Use:** If the platform is good, devs will *want* to use it.
*   **Abstract Too Much:** Leaky abstractions hurt. Let devs see the K8s YAML if they need to.

### Troubleshooting
*   **"Backstage is too hard":** It requires React/TypeScript skills. If your ops team is purely bash/python, Backstage might be a heavy lift. Consider a SaaS wrapper like Roadie.
*   **"Templates break":** Use a CI pipeline to test your templates (e.g., run the scaffolder in a test environment weekly).
