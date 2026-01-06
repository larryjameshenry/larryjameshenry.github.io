---
description: Brainstorm high-potential topics for multi-article content series based on a broad domain.
---

1. **Input**: Identify the broader domain or theme the user wants to brainstorm about. If not provided in the original request, ask the user for the "Input Domain/Theme".

2. **Research**: Perform a web search to find current trends, high-volume search queries, community discussions (Reddit, StackOverflow), and emerging technologies related to the inputs.
   - Use the `search_web` tool.

3. **Ideate**: Act as an expert Content Strategist and SEO Specialist. Based on the research, brainstorm 3-5 high-potential topics suitable for a "Topic Cluster" approach (1 Pillar Post + 5-10 Cluster Posts).
   - **Goal**: Identify topics deep enough for a series, not just single blog posts.
   - **Evaluate**: Explain *why* it requires a series and who the audience is.

4. **Report Generation**: Generate the content in the following Markdown format:

   ```markdown
   # Content Series Ideation: [Domain Name]

   ## Topic 1: [Topic Name]
   - **Concept**: [Brief description of the topic]
   - **Why a Series?**: [Explain the depth/complexity that justifies multiple articles]
   - **Target Audience**: [Who is this for?]
   - **Search Intent**: [Informational, Commercial, Transactional?]
   - **Key Trends/Data**: [Mention specific trend or search volume insight found during research]
   - **Potential Structure**:
       - **Pillar**: [Idea for the main guide]
       - **Clusters**: [List 3-5 potential sub-article ideas]

   ## Topic 2: [Topic Name]
   ...

   ---

   **Recommendation**:
   Select the strongest topic above to proceed with the `/new-topic-cluster` command.
   ```

5. **Save**: Save the generated output to `plans/[domain-slug]/ideation.md`.
   - Convert the input domain/theme to a kebab-case slug for the directory name (e.g., "DevOps Automation" -> "devops-automation").
   - Use the `write_to_file` tool.
