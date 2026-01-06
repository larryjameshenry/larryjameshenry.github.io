---
description: Research a topic thoroughly based on a provided outline or topic to create a knowledge base.
---

1. **Input**: Identify the "Input File" (Outline or Draft) and the "Topic".
   - If not provided, ask for them.

2. **Read Context**: Read the content of the "Input File".

3. **Perform Research**: Act as an expert technical researcher. Use `search_web` to conduct deep-dive research to fill gaps in the outline.
   - **Goal**: Create a "solid, not too long, but all-inclusive" knowledge base.
   - **Focus**: Density of facts, numbers, and concrete details. No fluff.

4. **Generate Report**: Create a Markdown research report covering:

   **1. Executive Summary & User Intent**
   - Core Definition
   - User Intent (What are they solving?)
   - Relevance (Why now?)

   **2. Key Technical Concepts & Details**
   - Components & Architecture
   - Terminology
   - Metrics/Limits (e.g., 50MB max)

   **3. Practical Implementation Data**
   - Standard Patterns
   - Code Snippets/Config patterns
   - Tools & Libraries

   **4. Best Practices vs. Anti-Patterns**
   - Do's (Production-ready)
   - Don'ts (Common mistakes)
   - Performance Tips

   **5. Edge Cases & Troubleshooting**
   - Common Errors
   - Limitations

   **6. Industry Context**
   - Trends & Alternatives

   **7. References**
   - Official Docs, RFCs

5. **Save**: Save to `plans/[topic-slug]/research/[article-slug].md`.
   - Derive labels from the Input File path.
   - Use the `write_to_file` tool.
