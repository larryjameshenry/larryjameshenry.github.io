---
title: "Platform Engineering 101: Building Your First Internal Developer Platform (IDP)"
date: 2025-12-04T00:00:00
draft: true
description: "A comprehensive guide to shifting from ticket-based ops to self-service platforms. Learn how to build a 'Golden Path' for developers using tools like Backstage."
series: ["DevOps Automation"]
tags: ["platform engineering", "internal developer platform", "backstage tutorial", "idp tools"]
categories: ["PowerShell", "DevOps"]
weight: 1
---

Are your DevOps engineers spending more time on operational overhead than on coding? This "Ticket Ops" approach often hinders velocity. As cloud architectures grow complex, the cognitive load on developers explodes. Expecting every dev to be a Kubernetes expert is unrealistic. The result is "Shadow IT," bottlenecked deployments, and burnt-out Ops teams.

Platform Engineering offers a way out: treating your infrastructure as a self-service product. This guide walks you through building your first Internal Developer Platform (IDP), enabling you to scale from 10 to 1000 services without scaling your Ops headcount. We’ll define what an IDP actually is, explore the "Golden Path" philosophy, and demonstrate building a basic portal using Backstage.

## Section 1: What is Platform Engineering?

### 1.1 Beyond DevOps: The Product Mindset

Platform Engineering is not just a rebrand of DevOps; it is a specific implementation of DevOps culture. While DevOps encourages collaboration, Platform Engineering builds the concrete structures to make that collaboration seamless. It requires a fundamental shift: treating developers as your *customers* and the platform as a *product*.

The primary goal is to reduce "Cognitive Load." Team Topologies defines this effectively: "The purpose of a platform team is to enable stream-aligned teams to deliver work with substantial autonomy." By removing extraneous cognitive load (like configuring a VPC peering connection), you allow developers to focus on germane load (like business logic).

### 1.2 The Core Components of an IDP

An Internal Developer Platform (IDP) consists of three main layers:

1.  **The Portal (Interface):** The "front door" where developers interact with the platform. This is often a UI like Backstage or a CLI tool. It aggregates documentation, templates, and service catalogs.
2.  **The Orchestrator (Brain):** The backend logic that executes requests. This could be a Platform Orchestrator like Humanitec, a GitOps controller like ArgoCD, or a set of custom automation scripts.
3.  **The Infrastructure (Resource):** The actual underlying cloud resources, such as Kubernetes clusters, AWS databases, or networking components.

## Section 2: Designing Your "Golden Path"

### 2.1 Defining the Path

A "Golden Path" (or Paved Road) is an opinionated, supported, and streamlined workflow for a common task. It is not a constraint; it is a guarantee. If a developer stays on the Golden Path, the platform team provides full support and ensures the system works.

For example, a "Create a Spring Boot Microservice" Golden Path might automatically provision:
*   A GitHub repository with a skeleton codebase.
*   A pre-wired CI/CD pipeline.
*   Kubernetes manifests for deployment.
*   Default monitoring dashboards and log aggregation.

Standardization leads to speed. When every service looks the same, security patching, library upgrades, and troubleshooting become manageable at scale.

### 2.2 Balancing Freedom and Standards

The biggest risk in Platform Engineering is building a "Golden Cage"—a system so rigid that it blocks innovation. You must allow for "Off-Roading." Developers should be free to deviate from the standard path if they have a specific need, but they must understand that they lose the platform's automated support. They essentially opt-in to "DIY Ops."

Start with a "Thinnest Viable Platform" (TVP). Do not try to build a massive enterprise portal on day one. Identify the single loudest complaint from your developers—perhaps it's provisioning a test database—and automate just that.

## Section 3: Choosing Your Tool Stack

### 3.1 The Portal Layer: Backstage vs. The Rest

Choosing the right interface is critical for adoption.

| Feature | **Backstage** | **Port** | **Atlassian Compass** |
| :--- | :--- | :--- | :--- |
| **Type** | Open Source Framework | SaaS Product | SaaS Product |
| **Cost** | Free (High Engineering Cost) | Paid (Per user/service) | Paid (Free tier available) |
| **Customization** | Unlimited (Code-first) | High (No-code/Low-code) | Medium (Opinionated) |
| **Maintenance** | High (You build & host it) | Low (Managed) | Low (Managed) |
| **Best For** | Engineering-heavy orgs needing control | Teams wanting speed & low maintenance | Atlassian-heavy shops |

**Backstage** (created by Spotify) is the industry standard for open-source portals. It offers immense power but requires a dedicated team to maintain. **SaaS alternatives** like Port provide a faster time-to-value but with less flexibility.

### 3.2 The Backend: GitOps as the Engine

Your IDP shouldn't touch the cloud directly. Instead, use GitOps as the engine. When a developer requests a new service in the portal, the IDP should simply commit a configuration file to a Git repository. A GitOps controller (like ArgoCD or Flux) then detects this change and syncs the infrastructure.

This ensures that Git remains the single source of truth. It provides an audit trail of who requested what and allows for instant rollbacks by simply reverting a commit.

## Hands-On Example: Scaffolding a Service with Backstage

We will set up a local instance of Backstage and configure a "Software Template" to scaffold a simple Node.js application.

**Prerequisites:** Node.js 16+, Yarn, Docker.

### Implementation Steps

1.  **Install Backstage:** Use the creation wizard to scaffold your portal.
    ```bash
    npx @backstage/create-app@latest
    # Follow the prompts to name your app (e.g., my-portal)
    cd my-portal
    yarn dev
    ```
    This will start the Backstage app at `localhost:3000`.

2.  **Create a Template:** Define a `template.yaml` file. This file tells Backstage what inputs to ask for and what actions to take.

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
    ```

3.  **Register the Template:** Go to `localhost:3000/catalog-import` and enter the URL to your `template.yaml`.

**Verification:**
Navigate to the "Create" page in Backstage. You should see your "Node.js Service" card. Click it, fill out the form, and watch as Backstage automatically creates a new repository in GitHub, commits the skeleton code, and registers it in your catalog.

## Best Practices & Optimization

**Do's:**
*   **Marketing is Key:** You have to "sell" the platform to your developers. Host launch parties, record demos, and create a brand for your internal product.
*   **Documentation First:** If the Golden Path isn't documented, it doesn't exist. Use "Docs-like-code" (TechDocs) to keep documentation close to the code.
*   **Focus on Day 2 Ops:** Don't just automate creation. Automate the painful Day 2 tasks: restarting services, resizing databases, and rotating credentials.

**Don'ts:**
*   **Mandate Adoption:** Don't force everyone to migrate on day one. Prove value with early adopters. If the platform is good, developers will *want* to use it.
*   **Hide Everything:** Don't abstract so much that developers don't know their app runs on Kubernetes. Leaky abstractions are painful; allow deep-diving when necessary.

## Troubleshooting Common Issues

**Issue 1: "Backstage is too hard to maintain"**
*   **Cause:** Backstage is a TypeScript/React application. Traditional Ops teams often lack these frontend skills.
*   **Solution:** Dedicate a frontend-savvy engineer to the platform team. Alternatively, consider a managed SaaS wrapper like Roadie to remove the maintenance burden.

**Issue 2: "The Templates are always broken"**
*   **Cause:** The underlying boilerplates (node versions, libraries) drift over time, causing new projects to fail immediately.
*   **Solution:** Treat templates as code. Implement a CI pipeline that runs your scaffolder in a test environment weekly to verify that generated projects still build and deploy correctly.

## Conclusion

**Key Takeaways:**
1.  **Platform Engineering** is about reducing friction and cognitive load, not just building shiny tools.
2.  **Golden Paths** are the deliverable; the IDP is just the interface. Focus on the workflow first.
3.  **Start Small:** A simple CLI tool that standardizes repo creation is a valid MVP platform. Don't over-engineer.

**Next Steps:**
*   Interview 5 developers to find their biggest bottleneck.
*   Spin up a POC of Backstage or Port to visualize the solution.
*   Define your first simple Golden Path (e.g., "Hello World" web app) and automate it.
