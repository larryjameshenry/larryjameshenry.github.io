---
description: Create a strategic content cluster plan based on research and specified article counts.
---

1. **Input**: Identify the "Topic", the "Research File" path, and the desired "Min Articles" / "Max Articles" (default 5-10).
   - If inputs are missing, ask the User.

2. **Read Research**: Read the content of the "Research File" using `read_resource` or `view_file`.

3. **Strategize**: Act as an expert content strategist. Based strictly on the provided research, create a strategic content plan.
   - **Goal**: One central "Pillar Post" + [Min] to [Max] supporting "Cluster Posts".

4. **Generate Plan**: Produce a Markdown report with the following structure:

   ```markdown
   ARTICLE_COUNT: [Total number of cluster articles]

   ---

   ### **Pillar Post**
   - **Proposed Title**: [Catchy and comprehensive title]
   - **Description**: [2-3 sentence summary linking all cluster posts]
   - **Target Audience**: [Primary audience from research]
   - **Primary Keywords**: [3-5 primary keywords]
   - **Key Questions Answered**:
       - [Question 1]
       - [Question 2]
       - ...

   ---

   ### **Cluster Posts**

   **Cluster Post 1: [Proposed Title]**
   - **Description**: [1-2 sentence summary]
   - **Target Audience**: [Specific audience]
   - **Primary Keywords**: [2-3 focused keywords]
   - **Key Questions Answered**:
       - [Question 1]
       - ...

   **Cluster Post 2: [Proposed Title]**
   ... [Continue for all cluster posts]
   ```

5. **Save**: Save the generated output to `plans/[topic-slug]/plan.md`.
   - Convert the "Topic" to a kebab-case slug for the folder name.
   - Use the `write_to_file` tool.
