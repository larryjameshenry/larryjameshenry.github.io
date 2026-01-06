---
description: Expand an article outline into a complete, publication-ready article using provided research and content.
---

1. **Input**: Identify the "Research File" (containing facts, details, metrics) and the "Outline File" (containing the structure).
   - If not provided, ask the user for these file paths.

2. **Read Context**: Read both files using `read_resource` or `view_file`.

3. **Draft Article**: Act as an expert technical writer and editor. Expand the Outline into a complete article using the Research.

   **CRITICAL RULES**:
   - **Synthesize**: Combine outline structure with research facts.
   - **Expand**: Turn every bullet point into full, engaging prose.
   - **Density**: Remove fluff. Every sentence must add value.
   - **Active Voice**: Use active voice (e.g., "PowerShell executes..." not "The script is executed by...").
   - **No Meta-commentary**: Do NOT say "We will cover..." or "Let's dive in". Just start.
   - **Specifics**: Use real numbers, error messages, and code.

   **FORBIDDEN WORDS** (Do not use):
   - delve, leverage, robust, seamless, cutting-edge, game-changer
   - "In the realm of", "At the end of the day", "It is important to note"

   **Content Requirements**:
   - **Code**: Must be complete, commented, and functional.
   - **Scenarios**: Include at least one step-by-step real-world example.
   - **Troubleshooting**: Include common errors and fixes.

   **Formatting**:
   - Return a single complete Markdown file.
   - **Front Matter**:
     - Preserve existing YAML.
     - Change `draft: true` to `draft: false`.
     - Update `date` to current timestamp.

4. **Save**: Save to `plans/[topic-slug]/drafts/[article-slug].md`.
   - Derive labels from the Context File paths.
   - Use the `write_to_file` tool.
