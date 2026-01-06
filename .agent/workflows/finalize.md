---
description: Final review, polish, and quality check of article before publishing.
---

1. **Input**: Identify the "Draft File" to be finalized.
   - If not provided, ask the user.

2. **Read Draft**: Read the content of the "Draft File".

3. **Review & Polish**: Act as an expert Technical Editor. Review against the following criteria:

   - **Content**: Accuracy, completeness, evidence, best practices.
   - **Code**: Syntax, conventions, comments, error handling.
   - **Structure**: Flow, transitions, intro/conclusion balance.
   - **Clarity**: Jargon usage, breakdown of complex concepts, active voice.
   - **SEO**: Title keywords, meta description, tags, headings.
   - **Formatting**: Hierarchy, markdown correctness.
   - **User Value**: Actionable info, relevant examples.
   - **Grammar**: Spelling, punctuation, tone.
   - **AI Pattern Detection** (CRITICAL):
     - **Banned**: delve, leverage, robust, seamless, game-changer, etc.
     - **Vague**: "significantly improves" (needs #), "very fast" (needs #).
     - **Formulaic**: starting paragraphs with "Moreover", "In conclusion".

4. **Generate Output**: Produce a report with two sections.

   **Section 1: Critique**:
   ```markdown
   ### OUTPUT 1: Critique and Recommendations
   **Critical Issues**: [Must Fix + Severity]
   **Content Improvements**: [Should Fix + Severity]
   **Style Enhancements**: [Nice to have]
   **What Works Well**: [...]
   **Priority Fixes**: [Top 5]
   **Score**: [0-100]%
   ```

   **Section 2: Improved Version**:
   The complete, polished article with all critical and medium issues fixed.
   - Ready for publication.
   - Proper extraction of front matter and content.

5. **Save**: Save the 'Improved Version' to `plans/[topic-slug]/ready/[article-slug].md`.
   - Derive labels from the Draft File path.
   - Use the `write_to_file` tool.
