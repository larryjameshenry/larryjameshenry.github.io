---
description: Fact-check an article for accuracy, verify claims, and identify unsupported statements.
---

1. **Input**: Identify the "Draft File" to be fact-checked.
   - If not provided, ask the user.

2. **Read Draft**: Read the content of the "Draft File" using `read_resource` or `view_file`.

3. **Verify**: Act as a rigorous Fact-Checker. Review the text against the following criteria:

   - **Technical Accuracy**: Syntax, API usage, versions, terminology.
   - **Factual Claims**: Performance metrics, limits, dates, features.
   - **Best Practices**: Security, modern patterns, deprecations.
   - **Code Examples**: Syntax, logic, error handling, dependencies.
   - **External References**: Links, authoritative sources.
   - **Logical Consistency**: Contradictions, scope.

4. **Report Generation**: Generate a detailed Markdown report.

   **Output Format**:
   ```markdown
   ### FACT-CHECK SUMMARY
   **Overall Severity**: [PASS / MINOR / MAJOR / FAIL]
   **Scores**:
   - Technical Accuracy: [0-100]%
   - Factual Claims: [0-100]%
   - Best Practices: [0-100]%
   - Code Examples: [0-100]%
   - **Overall Accuracy**: [0-100]%

   ### CRITICAL ISSUES (Must Fix)
   **Issue #[N]: [Description]**
   - **Location**: [ref]
   - **Problem**: [Explanation]
   - **Correct Info**: [Correction]
   - **Source**: [Verification]

   ### VERIFICATION NEEDED
   **Claim #[N]: [Description]**
   - **Statement**: "[Quote]"
   - **Issue**: [Why]
   - **Suggestion**: [Fix]

   ### MINOR ISSUES
   **Issue #[N]**: [Description]

   ### CODE VALIDATION
   **Code Block #[N]**:
   - **Status**: [Valid/Warning/Error]
   - **Issues**: ...

   ### RECOMMENDATIONS
   **Immediate Actions**: ...
   **Before Publishing**: ...
   ```

5. **Save**: Save to `plans/[topic-slug]/qa/[article-slug]-factcheck.md`.
   - Derive labels from the Context File path.
   - Use the `write_to_file` tool.
