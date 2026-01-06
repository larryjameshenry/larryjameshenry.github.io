---
description: Publish an article from the planning stage to the content/posts folder.
---

1. **Input**: Identify the "Article File" path (e.g., `plans/[topic-slug]/ready/[article-slug].md`).
   - If not provided, ask the user.

2. **Analyze Paths**:
   - Extract `[topic-slug]` and `[article-slug]` from the path.
   - Target Directory: `content/posts/[article-slug]/`.

3. **Create Structure**:
   - Create directory: `content/posts/[article-slug]/`.
   - Create subdirectories: `content/posts/[article-slug]/images/` and `content/posts/[article-slug]/files/`.
   - Use `run_command` with `mkdir -p`.

4. **Migrate Content**: Move files using `run_command` (PowerShell). Ensure you check if source files exist before moving to avoid errors, or use wildcards that might match nothing (PowerShell `Move-Item` might error if nothing matches, so be careful).

   - **Main Article**: Move `plans/[topic-slug]/ready/[article-slug].md` to `content/posts/[article-slug]/index.md`.
   - **Media**: Move `plans/[topic-slug]/media/*` to `content/posts/[article-slug]/images/`.
   - **Support Files**: Move contents of these folders to `content/posts/[article-slug]/files/`:
     - `plans/[topic-slug]/research/`
     - `plans/[topic-slug]/qa/`
     - `plans/[topic-slug]/promotion/`
     - `plans/[topic-slug]/outlines/`

   *Note: Use `mv` or `Move-Item`. Example:*
   ```powershell
   Move-Item -Path "plans/[topic-slug]/ready/[article-slug].md" -Destination "content/posts/[article-slug]/index.md"
   Get-ChildItem "plans/[topic-slug]/media/*" | Move-Item -Destination "content/posts/[article-slug]/images/"
   Get-ChildItem "plans/[topic-slug]/research/*" | Move-Item -Destination "content/posts/[article-slug]/files/"
   # ... repeat for other folders
   ```

5. **Verify**: Confirm that `content/posts/[article-slug]/index.md` exists.
