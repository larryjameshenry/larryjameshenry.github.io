---
description: Test code examples in article for syntax and basic logic errors.
---

1. **Input**: Identify the "Draft File" containing the code to test.
   - If not provided, ask for the path.

2. **Read Draft**: Read the content of the "Draft File".

3. **Code Validation**: Act as an expert Code Reviewer. Extract and validate all code examples against these criteria:

   - **Context**: Language, version, purpose.
   - **Syntax**: Correctness for the language.
   - **Logic**: Does it work? Are variables defined? Error handling?
   - **Common Issues**: Undefined vars, type mismatches, resource leaks.
   - **Best Practices**: Naming, comments, efficiency.
   - **Security**: Credential safety, injection prevention.
   - **Output**: Does comment output match reality?

4. **Generate Report**: Create a Code Validation Report.

   **Format**:
   ```markdown
   ### CODE VALIDATION SUMMARY
   **Score**: [0-100]
   **Stats**: [Total/Valid/Warning/Errors]
   **Status**: [PASS/WARN/FAIL]

   ### DETAILED ANALYSIS
   **Block #[N]**: [Location]
   - **Language**: [Lang]
   - **Status**: [Status]
   - **Issues**:
     - Critical: [Error]
     - Warning: [Issue]
   - **Fix**: [Corrected Code]

   ### CRITICAL ISSUES
   [List must-fix items]

   ### SECURITY ANALYSIS
   [List security findings]
   ```

5. **Save**: Save to `plans/[topic-slug]/qa/[article-slug]-code.md`.
   - Derive labels from the Draft File path.
   - Use the `write_to_file` tool.
