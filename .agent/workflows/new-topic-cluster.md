---
description: Create a comprehensive topic cluster plan (Research + Strategy) for a given topic.
---

1. **Input**: Identify the "Topic" to analyze.
   - Optional: Ask for "Min Articles" and "Max Articles" for the cluster (default to 5 and 10 if not specified).

2. **Phase 1: Research**: Act as an expert SEO analyst. Conduct deep-dive research on the topic.
   - **Core Concepts**: Define the topic and principles.
   - **Audience**: Identify Primary/Secondary audiences, goals, pain points, and expertise level.
   - **Sub-topics**: Identify key entities and sub-topics.
   - **Search Intent**: List common questions (who, what, where, why, how) grouped by intent (Informational, Commercial, Transactional).
   - **Competitors**: Analyze common angles and content gaps.
   - Use the `search_web` tool to gather this information.

3. **Phase 2: Strategy**: Create a Topic Cluster Plan based *strictly* on the research.
   - **Structure**: 1 Pillar Post + [Min] to [Max] Cluster Posts.
   - **Pillar Post**: Broad guide covering the core topic.
   - **Cluster Posts**: Specific articles targeting long-tail keywords/sub-topics.

4. **Report Generation**: Generate the output in the following Markdown format:

   ```markdown
   # Research Analysis: [Topic]

   [Insert Phase 1 Research Content Here]

   ---

   # Topic Cluster Plan: [Topic]

   **Strategy Summary**:
   - **Pillar Topic**: [Topic]
   - **Cluster Article Count**: [Total Number]

   ## **Pillar Post**
   - **Proposed Title**: [Catchy, SEO-friendly Title]
   - **Description**: [2-3 sentence summary of scope]
   - **Target Audience**: [Primary Audience]
   - **Primary Keywords**: [3-5 keywords]
   - **Key Questions Answered**:
     - [Question 1]
     - [Question 2]

   ## **Cluster Posts**

   **Cluster Post 1: [Proposed Title]**
   - **Description**: [1-2 sentence summary]
   - **Target Audience**: [Specific segment]
   - **Primary Keywords**: [2-3 keywords]
   - **Key Questions Answered**:
     - [Question]
     - [Question]

   **Cluster Post 2: [Proposed Title]**
   ... [Continue for all cluster posts]
   ```

5. **Save**: Save the generated output to `plans/[topic-slug]/plan.md`.
   - Convert the 'topic' input to a kebab-case slug for the folder name (e.g., "Terraform State" -> "terraform-state").
   - Use the `write_to_file` tool.
