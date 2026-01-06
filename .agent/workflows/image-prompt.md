---
description: Generate image generation prompts for an article (Nano Banana Pro).
---

1. **Input**: Identify the "Draft File" for which to generate prompts.
   - If not provided, ask the user.

2. **Read Draft**: Read the content of the "Draft File".

3. **Generate Prompts**: Act as an expert Creative Director. Analyze the article and create 3 distinct Nano Banana Pro prompts for a hero image.
   - **Audience**: Technical professionals.
   - **Vibe**: Modern, clean, professional, slightly abstract/futuristic.

   **Variations**:
   1. **Photorealistic / Cinematic**: High detail, dramatic lighting, depth of field.
   2. **3D Abstract / Isometric**: Clean 3D shapes, connecting nodes, soft lighting (Blender style).
   3. **Minimalist Vector / Flat**: Clean lines, symbolic.

4. **Prepare Output**: For each variation, provide:
   - **Concept**: Brief explanation.
   - **Prompt**: Exact prompt including "high quality", "masterpiece", "8k", "sharp focus", and aspect ratio (e.g., `--ar 16:9`).
   - **Negative Prompt**: Common issues to avoid (text, watermark, ugly, etc.).

5. **Save**: Save to `plans/[topic-slug]/media/[article-slug]-images.md`.
   - Derive labels from the Draft File path.
   - Use the `write_to_file` tool.
