---
description: Generate Mermaid.js diagram code to visualize technical concepts.
---

1. **Input**: Identify the "Context File" containing the text to visualize.
   - Optional: Identify specific "Concepts" to focus on. If not provided, focus on the most complex process or architecture found.

2. **Read Context**: Read the content of the "Context File" using `read_resource` or `view_file`.

3. **Analyze & Select**: Act as an expert Technical Architect.
   - Analyze the text to identify the process/flow/structure.
   - Select the best Mermaid diagram type:
     - **Flowchart**: Decision trees, workflows, steps.
     - **Sequence Diagram**: API calls, system interactions, authentication.
     - **Class Diagram**: Object structures, database schemas.
     - **State Diagram**: Lifecycle states.

4. **Generate Diagram**: Generate valid Mermaid.js code and a description.

   **Output Format**:
   ```markdown
   ### Diagram Description
   [Brief description of visualization]

   ### Mermaid Code
   ```mermaid
   [Insert valid Mermaid code]
   ```

   **Visual Notes**:
   *   [Note on specific relationships]
   *   [Note on abstractions]
   ```

5. **Save**: Save to `plans/[topic-slug]/media/[article-slug]-diagrams.md`.
   - Derive labels from the Context File path.
   - Use the `write_to_file` tool.
