---
description: Generate a detailed article outline with Hugo front matter from research notes or a topic cluster plan.
---

1. **Input**: Identify the "Target" (article name or reference) and the "Context File" path.
   - If not provided, ask the user for the `Target` (e.g., "Pillar Post", "Article 1") and the `Context File` (path to a plan.md or research.md).

2. **Read Context**: Use `read_resource` (or `view_file` if local) to read the "Context File".

3. **Analyze**: Act as an expert technical content strategist.
   - **If Context is a Topic Cluster Plan**:
     - Locate the specific article in the plan using the "Target" reference.
     - Extract: Title, Description, Target Audience, Keywords, Key Questions.
     - Extract `Series Name` from plan metadata.
     - Use article number for `weight` (0 for Pillar).
   - **If Context is Research Notes**:
     - Use "Target" as the main topic title.
     - Synthesize notes to build the outline.

4. **Generate Outline**: Create a comprehensive, production-ready Markdown outline with Hugo Front Matter.

   **Structure**: (Follow strictly)

   ```markdown
   ---
   title: "[Title from Plan OR Optimized SEO Title]"
   date: [Current Date YYYY-MM-DDTHH:MM:SS]
   draft: true
   description: "[Description from Plan OR 150-160 char summary]"
   series: ["[Series Name from Plan OR leave empty]"]
   tags: ["[Keyword 1]", "[Keyword 2]", "[Keyword 3]"]
   categories: ["PowerShell", "DevOps"]
   weight: [Article Number OR omit]
   ---

   ## Article Structure

   ### Introduction (150-200 words)
   **Hook**: [Engaging opening]
   **Problem/Context**: [Why this matters]
   **Value Proposition**: [3-5 outcomes]
   **Preview**: [Overview]

   ### [Main Section 1: Title]
   #### [Subsection 1.1: Key Concept]
   **Key Points**:
   - [Point 1]
   - [Point 2]
   **Content Elements**:
   - [PLACEHOLDER: Explanation]
   - [PLACEHOLDER: Diagram]

   #### [Subsection 1.2: Practical Application]
   **Key Points**: ...
   **Content Elements**: [Code example, Real-world scenario]

   ### [Main Section 2: Title]
   ...

   ### Hands-On Example: [Scenario Name]
   **Scenario**: [Description]
   **Prerequisites**: [Tools/Access]
   **Implementation Steps**:
   1. [Step 1]
   2. ...
   **Code Solution**: [PLACEHOLDER: Complete script]
   **Verification**: [How to confirm success]

   ### Best Practices & Optimization
   **Do's**: ...
   **Don'ts**: ...
   **Performance & Security**: ...

   ### Troubleshooting Common Issues
   **Issue 1: [Error]**: Cause & Solution
   **Issue 2: [Error]**: Cause & Solution

   ### Conclusion
   **Key Takeaways**: ...
   **Next Steps**: ...
   ```

5. **Save**: Save to `plans/[topic-slug]/outlines/[article-slug].md`.
   - Derive `[topic-slug]` from the parent folder of the Context File.
   - Derive `[article-slug]` by converting the article title to kebab-case.
   - Use the `write_to_file` tool.
