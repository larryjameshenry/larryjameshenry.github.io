# Fact-Check Report: Platform Engineering 101: Building Your First Internal Developer Platform (IDP)

This report verifies the technical claims, tool capabilities, and code accuracy in the "Platform Engineering 101" draft.

## 1. Tools and Technologies

*   **Backstage:**
    *   **Claim:** Requires TypeScript/React knowledge to maintain.
    *   **Verification:** **TRUE**. Backstage is a framework, not a turnkey product. Customizing it involves writing React plugins.
    *   **Claim:** Created by Spotify.
    *   **Verification:** **TRUE**.
    *   **Claim:** Uses `npx @backstage/create-app` for scaffolding.
    *   **Verification:** **TRUE**. This is the standard CLI command.

*   **Port:**
    *   **Claim:** SaaS alternative with lower maintenance but less code-level flexibility than Backstage.
    *   **Verification:** **TRUE**. Port is a commercial IDP product.

*   **Team Topologies:**
    *   **Claim:** Defines "Stream-aligned teams" and "Platform teams" with the goal of reducing cognitive load.
    *   **Verification:** **TRUE**. This is the core thesis of the Team Topologies methodology by Skelton and Pais.

## 2. Code Examples

*   **Backstage Software Template (`template.yaml`):**
    *   **Context:** Defining a scaffolder template.
    *   **Accuracy:**
        *   **API Version:** `apiVersion: scaffolder.backstage.io/v1beta3` is the correct current version.
        *   **Steps:** The actions `fetch:template`, `publish:github`, and `catalog:register` are the standard built-in actions for this workflow.
        *   **Parameters:** The use of `ui:field: OwnerPicker` and `RepoUrlPicker` is correct for the Backstage UI. **VERIFIED.**

*   **Shell Commands:**
    *   **Context:** Installing Backstage.
    *   **Accuracy:** `npx @backstage/create-app@latest` and `yarn dev` are correct. **VERIFIED.**

## 3. Concepts and Definitions

*   **Golden Path:** Correctly defined as an opinionated, supported workflow (as opposed to a mandatory "Golden Cage").
*   **Thinnest Viable Platform (TVP):** Accurately described as a strategy to start small (e.g., with just a wiki or CLI) rather than over-engineering.
*   **IDP Architecture:** The distinction between the Portal (interface), Orchestrator (logic), and Infrastructure is a standard architectural view in the Platform Engineering community.

## Conclusion

The article is factually accurate. The Backstage template example is particularly valuable as it uses the correct, modern API syntax.
