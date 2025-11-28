# Gemini CLI Content Generation Workflow

This document describes the complete content generation workflow for creating high-quality blog articles. Use this context when responding to content generation requests.

## Workflow Overview

The content generation pipeline consists of 7 stages:

```
Research → Plan → Breakdown → Outline → Expand → Test → Publish
```

Each stage builds on the previous one, using incremental prompts to work within API rate limits.

---

## Stage 1: Research

**Purpose**: Gather comprehensive information on a topic to serve as the knowledge base for all subsequent stages.

**Input**: Topic name (e.g., "PowerShell Automation")

**Process**:
- Execute 5 focused research queries (not one large query)
- Each query targets a specific aspect:
  1. **Overview**: Definition, significance, current relevance
  2. **Key Concepts**: 5-7 most important components or aspects
  3. **Practical Applications**: 3-4 real-world use cases
  4. **Best Practices**: 5-7 proven approaches and patterns
  5. **Common Challenges**: 3-5 frequent problems and pitfalls

**Output**: Research document with 5 distinct sections

**Quality Guidelines**:
- Keep each query focused and under 300 words target response
- Avoid requesting too much in one call to prevent rate limits
- Use specific language to guide detailed responses
- Request accurate, up-to-date information
- Include real examples and metrics

---

## Stage 2: Plan

**Purpose**: Create a strategic content cluster plan with pillar and supporting articles.

**Input**: Topic name + Research document

**Process**:
- Analyze research to identify article topics
- Create pillar article outline (comprehensive overview)
- Define 5-12 supporting articles
- Establish content taxonomy (series, tags, categories)
- Plan internal linking structure
- Define content progression and publication order

**Output**: Comprehensive content cluster plan including:
- Pillar article title, description, keywords, structure
- Supporting articles (numbered, with descriptions, key points, keywords)
- Series name and taxonomy
- Internal linking recommendations
- Suggested publication order

**Quality Guidelines**:
- Pillar article should be 2000-3000 words
- Supporting articles should be 1000-1500 words each
- Include clear article count at the beginning: `ARTICLE_COUNT: [number]`
- Describe each article with specific focus areas
- Provide realistic keyword recommendations

---

## Stage 3: Breakdown

**Purpose**: Extract individual article outlines from the cluster plan.

**Input**: Cluster plan + specific article number or "Pillar"

**Process**:
- Parse the plan to identify the requested article
- Create detailed outline with:
  - Title and description
  - 3-5 main sections
  - Key points for each section
  - Placeholder markers for content to expand
  - Hugo front matter template

**Output**: Individual article outline ready for expansion

**Quality Guidelines**:
- Maintain semantic accuracy from plan
- Create logical section hierarchy
- Include actionable key points
- Mark all areas needing expansion clearly: `[PLACEHOLDER: description]`
- Ensure outline can expand to 1200-1800 words

---

## Stage 4: Outline

**Purpose**: Create detailed article outlines from research notes with full Hugo front matter.

**Input**: Research document + topic/article focus

**Process**:
- Extract key information from research
- Structure into logical sections
- Create comprehensive outline with:
  - Introduction (hook, problem, value prop, preview)
  - 3-5 main content sections with subsections
  - Practical examples section
  - Best practices section
  - Troubleshooting section
  - Conclusion with key takeaways
  - Hugo front matter (title, date, draft, series, tags, category)

**Output**: Ready-to-expand outline with all metadata

**Quality Guidelines**:
- Target 1500-2500 final word count
- Include specific metrics and examples
- Prepare space for 2-3 code examples
- Plan for step-by-step walkthroughs
- Mark all expansion points clearly

---

## Stage 5: Expand

**Purpose**: Transform outline into complete, publication-ready article.

**Input**: Article outline

**Process** (Incremental Expansion Strategy):
- Parse outline into logical chunks (2-5 sections per request for Quality mode)
- Build comprehensive writing context shared across all requests
- For each chunk:
  1. Generate 400-600 word expansion (Quality), 250-400 (Conservative), or 150-250 (Minimal)
  2. Implement writing guidelines
  3. Wait 8-20 seconds before next request (depends on mode)
  4. Retry up to 3 times with exponential backoff on rate limits
- Generate introduction (200-250 words)
- Generate conclusion (200-250 words)
- Combine all parts into final article

**Output**: Complete article (1500-2500 words) with draft: false

**Expansion Modes**:

### Quality Mode (Recommended)
- Groups 2-3 related sections per request
- Better context for coherent writing
- Higher quality output
- May hit rate limits on free tier
- Delay: 8 seconds between requests
- Estimated time: 2-3 minutes for 8-section article

### Conservative Mode
- One section per request
- Good balance of quality and reliability
- Medium word count targets
- Delay: 15 seconds between requests
- Estimated time: 3-4 minutes for 8-section article

### Minimal Mode
- Smallest chunks possible
- Most reliable on free tier
- Lower quality trade-off
- Splits large sections
- Delay: 20 seconds between requests
- Estimated time: 6-8 minutes for 8-section article

**Writing Guidelines (Critical)**:

### Avoid AI Clichés
❌ NEVER use:
- "delve", "leverage", "robust", "seamless", "cutting-edge", "game-changer"
- "In the realm of", "when it comes to", "at the end of the day"
- "Let's dive into", "Let's explore", "It's worth noting"
- "Significantly improves", "dramatically enhances" (without metrics)

### Use Specific, Concrete Language
❌ Vague: "This tool can help you work more efficiently"
✅ Specific: "This tool reduces processing time from 45 minutes to 3 minutes, a 93% improvement"

❌ Vague: "Best practices recommend..."
✅ Specific: "When using X, performance improves 15-40% when you implement Y approach, especially for datasets over 10GB"

### Code Examples
- Include 2-3 complete, working examples
- Add explanatory comments explaining what AND why
- Show expected output as comments
- Use realistic variable names
- Include error handling where appropriate
- Reference relevant best practices in comments

### Structure and Clarity
- Use active voice: "The script executes" not "Execution occurs"
- Start sentences directly: "Use arrays for" not "It's recommended to use arrays for"
- Break complex concepts into digestible explanations
- Front-load important information: key takeaway first, then details
- Use subheadings for scannability

### Evidence and Context
- Support claims with numbers: "43% of developers reported...", "2-3x faster"
- Reference real-world scenarios
- Explain limitations and edge cases
- Provide prerequisites clearly
- Show before/after comparisons

---

## Stage 6: Test

**Purpose**: Validate technical accuracy, code correctness, and factual claims.

**Input**: Complete article

**Process**:

### Test-ArticleAccuracy.ps1
- Verify technical accuracy of all claims
- Check command syntax and parameters
- Validate API usage and method signatures
- Confirm version numbers and compatibility
- Verify performance claims with realistic metrics
- Check factual accuracy of statistics and dates
- Identify claims needing evidence or sources

### Test-ArticleCode.ps1
- Extract all code blocks
- Validate syntax for each language
- Check code logic matches article claims
- Identify undefined variables or type mismatches
- Find security issues (hardcoded credentials, injection vulnerabilities)
- Verify expected output matches code logic
- Test error handling

**Output**: Validation reports with:
- Overall quality score (0-100)
- Issues by severity (critical, warning, minor)
- Specific line numbers and recommendations
- Security analysis results

**Quality Guidelines**:
- Critical issues must be fixed before publishing
- Warnings should be addressed
- Minor issues can be documented
- Code examples must be executable and accurate
- Claims must be verifiable or attributed

---

## Stage 7: Publish

**Purpose**: Mark article as ready for production and update metadata.

**Input**: Tested and approved article

**Process**:
- Change `draft: true` to `draft: false`
- Verify all metadata (title, date, tags, category, series)
- Ensure all resource files are in place (images, downloads)
- Update table of contents if needed
- Create cross-links to related articles
- Verify Hugo build succeeds: `hugo`

**Output**: Published article in production

**Quality Guidelines**:
- All tests must pass
- No placeholder sections remaining
- Minimum 1500 words
- All code examples tested
- All links verified
- All images included and optimized

---

## Hugo Page Bundles

Articles use Hugo page bundle structure for better organization:

```
content/posts/article-slug/
├── index.md           # Main article content
├── README.md          # Bundle documentation
├── images/           # Article-specific images
│   ├── diagram.png
│   └── screenshot.png
└── files/            # Downloadable resources
    ├── script.ps1
    └── config.yaml
```

**References in Markdown**:
- Images: `![Alt text](images/filename.png)`
- Files: `[Download](files/filename.zip)`

---

## Rate Limit Handling

For free tier Gemini API:
- 15 requests per minute
- 1,500 requests per day
- 429 error indicates rate limit exceeded

**Strategy**:
1. Keep requests small (under 1000 tokens each)
2. Use delays between requests:
   - Minimum: 5 seconds
   - Conservative: 8-10 seconds
   - Safe: 15-20 seconds
3. On 429 error: exponential backoff (20s, 40s, 60s)
4. Maximum 3 retries per request
5. Split large tasks into smaller chunks

---

## Writing Quality Checklist

Before marking article as complete, verify:

- [ ] **No AI clichés** - Search for prohibited phrases
- [ ] **Specific metrics** - Claims backed by numbers (2x faster, 43% improvement, $50/month)
- [ ] **Code examples** - 2-3 working examples with comments
- [ ] **Practical guidance** - Real-world scenarios and walkthroughs
- [ ] **Active voice** - Direct, clear statements
- [ ] **Proper structure** - Clear hierarchy with subheadings
- [ ] **Conclusion** - 5 specific, actionable takeaways
- [ ] **No placeholder sections** - All [PLACEHOLDER: x] replaced
- [ ] **Minimum length** - 1500+ words for full articles
- [ ] **Tested code** - All code blocks verified to work
- [ ] **Accurate facts** - Claims verified or attributed
- [ ] **Front matter complete** - Title, date, tags, category, series
- [ ] **Links working** - All internal and external links valid
- [ ] **Images included** - All referenced images present

---

## Common Prompt Templates

### Research Prompt
```
Research [topic] comprehensively.

Provide information on:
1. Overview and definition
2. Key concepts (3-5 items)
3. Practical applications (2-3 use cases)
4. Best practices (3-5 tips)
5. Common challenges (2-3 issues)

Keep response under 500 words total.
```

### Planning Prompt
```
Create a content cluster plan for: [topic]

Include:
- Pillar article (2000-3000 words)
- 5-12 supporting articles (1000-1500 each)
- Internal linking strategy
- Taxonomy (series, tags, categories)
- Publication order

Start response with: ARTICLE_COUNT: [number]
```

### Expansion Prompt
```
Expand this outline into 400-600 word article section:

[outline content]

Guidelines:
- Avoid AI clichés: delve, leverage, robust, seamless
- Use specific metrics and examples
- Include code examples with comments
- Explain WHY, not just HOW
- Active voice, direct statements

Maintain heading structure.
```

---

## Troubleshooting

### Rate Limit Errors (429)
- Increase delay between requests
- Reduce chunk size
- Reduce request frequency
- Wait 30-60 minutes before retrying
- Consider upgrading API plan

### Low Quality Output
- Use Quality mode instead of Minimal
- Provide more detailed context prompts
- Include specific examples in prompts
- Increase word count targets
- Add more detailed writing guidelines

### Missing Sections
- Check [PLACEHOLDER] markers are replaced
- Run expansion again for failed sections
- Manually complete placeholder sections
- Review test reports for issues

### Code Examples Failing
- Verify syntax for correct language/version
- Test examples locally before including
- Add error handling and edge case notes
- Include expected output as comments
- Provide prerequisites clearly

---

## API Plan Recommendations

**Free Tier**: Good for learning and prototyping
- Works with Conservative or Minimal modes
- 1500 requests/day limit
- Suitable for 10-15 articles per week

**Pay-as-you-go** (~$0.0005-0.001 per request):
- Enables Quality mode reliably
- No daily limits
- Cost-effective for regular content creation
- 100+ articles per month for <$10

**Pro Plans**: For high-volume production
- Faster rate limits
- Higher token limits per request
- Volume discounts

---

## Summary

This workflow balances automation with quality control:

1. **Research** - Gather authoritative information
2. **Plan** - Structure content strategically
3. **Outline** - Create detailed article templates
4. **Expand** - Generate comprehensive content
5. **Test** - Validate accuracy and quality
6. **Publish** - Release to production

Each stage uses incremental, focused prompts to maximize API efficiency while maintaining high-quality output within rate limit constraints.

Use this workflow iteratively for consistent, high-quality technical content.
