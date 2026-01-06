---
description: Generate social media posts and newsletter copy to promote an article.
---

1. **Input**: Identify the "Article File" (ready-to-publish MD file).
   - If not provided, ask for the path.

2. **Read Article**: Read the content of the "Article File".

3. **Generate Promotion Kit**: Act as an expert Developer Advocate. Analyze the article to extract the core value, surprising insights, and hooks. Generate content for:

   **1. LinkedIn Post** (Professional):
   - **Tone**: Authoritative, helpful.
   - **Structure**: Hook, Context (Pain Point), Solution (Bullets), Call to Action.
   - **Hashtags**: 3-5 technical tags.

   **2. Twitter/X Thread** (Punchy):
   - **Tone**: "Building in public", fast-paced.
   - **Tweets**:
     1. Hook (Killer feature/problem).
     2. Old Way (Struggle).
     3. New Way (Solution).
     4. Key Takeaway/Hint.
     5. Link + CTA.

   **3. Newsletter Blurb** (Personal):
   - **Tone**: Email from a smart colleague.
   - **Structure**:
     - 3 Subject Line Options (Clickable, not clickbait).
     - Body: 2-3 paragraphs. Why I wrote this + Why care now.

   **4. Reddit/Hacker News Titles**:
   - Option 1: Educational ("How I...").
   - Option 2: Controversial ("Why you should stop...").
   - Option 3: Resource ("Complete guide to...").

4. **Save**: Save to `plans/[topic-slug]/promotion/[article-slug]-promo.md`.
   - Derive labels from the Article File path.
   - Use the `write_to_file` tool.
