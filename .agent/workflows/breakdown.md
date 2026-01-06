---
description: Break down a topic cluster plan into detailed individual article article outlines.
---

1. **Input**: Identify the "Article Reference" (e.g., "Pillar Article", "Article 1", "Cluster Post 3") and the "Plan File" path.
   - If inputs are missing, ask the User.

2. **Read Plan**: Read the content of the "Plan File" using `read_resource` or `view_file`.

3. **Generate Breakdown**: Act as an expert content writer. Extract details for the specified article from the plan and generate a production-ready Markdown outline.

   **Front Matter**:
   ```yaml
   ---
   title: "[Engaging, SEO-friendly title from plan]"
   date: [current date ISO format]
   draft: true
   description: "[Compelling 150-160 char meta description]"
   series: ["[series name from plan]"]
   tags: ["[tag1]", "[tag2]", "[tag3]"]
   categories: ["[category from plan]"]
   weight: [article number, 0 for pillar]
   ---
   ```

   **Article Structure**:
   ```markdown
   ## Article Structure Outline

   ### Introduction (150-200 words)
   **Hook**: [Engaging opening]
   **Problem/Context**: [Why this matters]
   **What Reader Will Learn**: [3-5 takeaways]
   **Preview**: [Overview]

   ### [Main Section 1 Title]
   #### [Subsection 1.1]
   **Key Points**:
   - [Point 1]
   **Content Notes**:
   - [PLACEHOLDER: Explanation]
   - [PLACEHOLDER: Diagram]

   ... [Continue sections]

   ### Practical Example: [Scenario Title]
   **Scenario**: [Description]
   **Requirements**: [List]
   **Implementation**: [Step-by-step]
   **Code Example**: [PLACEHOLDER: Complete code]
   **Expected Results**: [Output]

   ### Best Practices & Tips
   **Do's**: ...
   **Don'ts**: ...
   **Performance**: ...
   **Security**: ...

   ### Troubleshooting Common Issues
   **Issue 1: [Problem]**: Cause & Solution ...

   ### Conclusion
   **Key Takeaways**: ...
   **Next Steps**: ...
   **Related Articles**: [Links]

   ---
   ## Author Notes
   - Target Word Count: 1200-1800
   - Tone: Professional but conversational
   - Audience: [From Plan]
   ```

4. **Save**: Save the generated output to `plans/[topic-slug]/outlines/[article-slug].md`.
   - Derive `[topic-slug]` from the Plan File path.
   - Derive `[article-slug]` by converting the Article Reference title to kebab-case.
   - Use the `write_to_file` tool.
