# Technical Writing Style Guide

## Voice and Tone

### Target Voice
- **Conversational but Professional**: Like explaining to a colleague over coffee
- **Technical but Accessible**: Expert knowledge without gatekeeping
- **Confident but Humble**: Share knowledge without arrogance
- **Practical but Thorough**: Focus on utility with complete context

### Tone Characteristics
- Direct: Get to the point quickly
- Helpful: Anticipate reader questions
- Honest: Acknowledge limitations and trade-offs
- Respectful: Assume reader intelligence

## Sentence Structure

### Preferred Patterns
- **Active voice**: "PowerShell executes scripts" not "Scripts are executed by PowerShell"
- **Imperative for instructions**: "Run the command" not "You should run the command"
- **Varied length**: Mix short punchy sentences with longer explanatory ones
- **Front-load key info**: Put important details first

### Examples
❌ "It can be seen that the performance improvements are quite significant"
✅ "Performance improved by 40%"

❌ "The user should be aware that there are several considerations"
✅ "Consider these three factors: reliability, cost, and maintenance"

## Paragraph Structure

### Opening Sentences
- State the main point immediately
- Avoid throat-clearing phrases
- Make it clear why this paragraph matters

### Body
- 3-5 sentences ideal
- Each sentence adds new information
- Support claims with evidence
- Use examples liberally

### Technical Content
- Code before explanation for simple concepts
- Explanation before code for complex concepts
- Always explain WHY, not just HOW

## Word Choice

### Prefer Simple Words
- Use: start, not: initiate
- Use: end, not: terminate
- Use: show, not: demonstrate
- Use: use, not: utilize (unless specific technical meaning)
- Use: help, not: facilitate

### Prefer Concrete Words
- Use: "500ms response time", not: "fast"
- Use: "consumes 256MB RAM", not: "lightweight"
- Use: "handles 10K users", not: "scalable"

### Prefer Specific Words
- Use: "Docker container", not: "containerized solution"
- Use: "Git commit", not: "version control operation"
- Use: "Azure Function", not: "serverless compute"

## Technical Explanations

### Pattern: Context → Code → Explanation → Application
1. **Context**: Why this matters (1 sentence)
2. **Code**: Working example
3. **Explanation**: How it works
4. **Application**: When to use it

### Example
```powershell
try {
    $result = Invoke-RestMethod -Uri $apiUrl
} catch {
    Write-Error "API call failed: $_"
    exit 1
}
```
The try-catch block captures errors from the API call. If the call fails,
the script logs a descriptive error and exits with a non-zero code.

Use this pattern for any external API calls, file operations, or network requests
where failures are possible.


## PowerShell-Specific Guidelines

### Code Style
- Use full cmdlet names in articles (not aliases)
- Include parameter names explicitly
- Add comments for non-obvious logic
- Show expected output as comments

### Example Format
Get all running processes consuming over 100MB
```powershell
Get-Process | Where-Object { $.WorkingSet -gt 100MB } |
Select-Object Name, @{Name="MemoryMB";Expression={[math]::Round($.WorkingSet/1MB,2)}}
```
Output:
Name MemoryMB
---- --------
chrome 256.45
code 189.23


## Section Headings

### Characteristics
- Descriptive, not clever
- Front-loaded with keywords
- Parallel structure within article
- Action-oriented for how-to content

### Examples
❌ "Getting Started on Your Journey"
✅ "Install and Configure PowerShell"

❌ "Exploring the Possibilities"
✅ "Common Use Cases"

❌ "Taking Things to the Next Level"
✅ "Advanced Patterns"

## Lists

### When to Use
- **Bulleted**: Related items, no specific order
- **Numbered**: Sequential steps, ranked items
- **Definition**: Term-explanation pairs

### Structure
- Parallel grammatical structure
- Complete sentences or all fragments (not mixed)
- 3-7 items ideal (break longer lists into subsections)

### Examples

**Good - Parallel Structure:**
- Install dependencies
- Configure environment variables
- Run the setup script
- Verify installation

**Bad - Mixed Structure:**
- Install dependencies
- You should configure environment variables
- Running the setup script
- Verification of the installation

## Code Comments

### In Articles
- Explain WHY, not WHAT (code shows what)
- Add context for non-obvious choices
- Reference documentation for complex topics
- Show expected output when helpful

### Example
Use -ErrorAction Stop to ensure errors are caught by try-catch
Without this, non-terminating errors would be silently ignored
```powershell
try {
$data = Get-Content "config.json" -ErrorAction Stop
} catch {
# Provide helpful error message with troubleshooting hint
Write-Error "Config file not found. Run: New-Config.ps1"
exit 1
```

## Linking and References

### Internal Links
- Link to related articles naturally in text
- Use descriptive anchor text (not "click here")
- Reference previous articles in series with context

### External Links
- Link to official documentation
- Prefer stable URLs (avoid blog posts that might disappear)
- Mention link context: "See Microsoft's documentation on..."

### Code References
- Link to GitHub repos for large code samples
- Include version numbers for API references
- Cite sources for techniques or patterns

## Examples and Scenarios

### Real-World Scenarios
- Base on actual problems
- Include realistic data
- Show complete, working solutions
- Mention edge cases

### Example Structure
Scenario: Deploy Multiple Apps with Single Script
You manage 5 web applications that need daily deployment. Manual deployment
takes 30 minutes per app.
This script automates the entire process:
[code example]
The script reduces deployment time to 5 minutes total and eliminates human error.


## Conclusions

### Strong Endings
- Summarize 3-5 key takeaways
- Provide specific next actions
- Link to related content
- End with confidence, not apology

### Pattern
1. Restate the main benefit
2. List concrete takeaways
3. Suggest next steps
4. Link to continuation (if series)

### Example
Key Takeaways
You now have a complete PowerShell automation pipeline that:
- Reduces deployment time by 80%
- Eliminates manual errors
- Provides audit logging
- Scales to hundreds of applications

Next, implement error notifications by adding email alerts to the catch blocks.
For production deployment, see "PowerShell Automation: Production Best Practices"
in this series.
