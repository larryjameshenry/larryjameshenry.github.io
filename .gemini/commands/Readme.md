# Gemini CLI Content Workflow (Interactive Mode)

This document outlines the standard workflow for creating content using the Gemini CLI command templates directly within the interactive session.

In this mode, you don't type `gemini` at the start of every line. Instead, you simply type the slash command.

**Note on Redirecting Output (`>`)**:
In interactive mode, you cannot directly redirect output to a file using `>` like in PowerShell. You will see the output in the chat window. To save it, copy the output to a file, or ask the assistant to "save the last response to [filename]".

## 1. Ideation & Brainstorming
**Command:** `/ideate`
**Goal:** Brainstorm high-potential topics for a multi-article series based on a broad domain, utilizing web research and trend analysis.

```text
/ideate "DevOps Automation"
```
*Action: Review the suggested topics and select one to proceed with for the Topic Cluster Planning step.*

## 2. Topic Cluster Planning
**Command:** `/new-topic-cluster`
**Goal:** Create a strategic content plan with a Pillar Post and supporting Cluster Posts.

```text
/new-topic-cluster topic:"Azure DevOps Pipelines" min_articles:5 max_articles:8
```
*Action: Copy the output and save it to `plans/azure-devops-pipelines.md`*

## 3. Individual Article Outline
**Command:** `/outline`
**Goal:** Generate a detailed Hugo-compatible outline for a specific article from your plan or research.

You must first **add the context file** to your session so the command can see it.

```text
@plans/azure-devops-pipelines.md /outline "Article 1"
```
*Action: Copy the output and save it to `content/posts/azure-pipelines-intro/index.md`*

## 4. Deep Research
**Command:** `/research`
**Goal:** Conduct specific technical research to fill in the gaps of your outline.

```text
@content/posts/azure-pipelines-intro/index.md /research "Azure DevOps Pipelines"
```
*Action: Copy the output and save it to `content/posts/azure-pipelines-intro/files/research.md`*

## 5. Expand to Full Article
**Command:** `/expand`
**Goal:** Turn the outline and research into a full, publication-ready draft.

You can reference multiple files to give the model all the necessary context.

```text
@content/posts/azure-pipelines-intro/files/research.md @content/posts/azure-pipelines-intro/index.md /expand
```
*Action: Copy the Markdown output and overwrite `content/posts/azure-pipelines-intro/index.md`*

## 6. Technical Visualization
**Command:** `/diagram`
**Goal:** Generate Mermaid.js code to visualize complex architectures, flows, or processes described in your article.

```text
@content/posts/azure-pipelines-intro/index.md /diagram "CI/CD Build Pipeline Flow"
```
*Action: Copy the mermaid code block into your article markdown file.*

## 7. Quality Assurance & Validation

### Code Validation
**Command:** `/testcode`
**Goal:** Check all code blocks for syntax, logic, and security issues.

```text
@content/posts/azure-pipelines-intro/index.md /testcode
```

### Fact-Checking
**Command:** `/factcheck`
**Goal:** Verify technical claims, version numbers, and accuracy.

```text
@content/posts/azure-pipelines-intro/index.md /factcheck
```

## 8. Visuals
**Command:** `/image-prompt`
**Goal:** Generate prompts for text-to-image tools (Midjourney, DALL-E 3) for your featured image.

```text
@content/posts/azure-pipelines-intro/index.md /image-prompt
```

## 9. Final Polish
**Command:** `/finalize`
**Goal:** Final editorial review and polish before publishing.

```text
@content/posts/azure-pipelines-intro/index.md /finalize
```

## 10. Promotion
**Command:** `/promote`
**Goal:** Generate social media copy (LinkedIn, Twitter/X) and newsletter blurbs to distribute your content.

```text
@content/posts/azure-pipelines-intro/index.md /promote
```
*Action: Save the output to a `promotion.md` file or schedule your posts immediately.*

## 11. Publish Article
**Command:** `/publish`
**Goal:** Promote the finalized article and its associated files from the `plans/` directory to the `content/posts/` directory in Hugo Page Bundle format.

```text
@plans/azure-devops-pipelines/ready/pillar-post.md /publish
```
*Action: The article and its assets are moved to `content/posts/` ready for Hugo to build.*

---

## Tips for Interactive Mode

1.  **Context (`@`):** Always use `@filename` to "attach" the relevant file to your prompt. This is how the command knows what to research, expand, or test.
2.  **Saving Output:** Since you can't use `> file.md`, you can simply tell the assistant: *"Save that output to content/posts/my-article/index.md"* after it generates the text.
3.  **Chaining:** You can ask follow-up questions naturally. For example, after running `/factcheck`, you can say *"Fix issue #2 and #3 in the article."*
