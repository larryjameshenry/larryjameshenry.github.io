<#
.SYNOPSIS
    Fact-check an article using Gemini CLI
.DESCRIPTION
    Uses Gemini CLI to verify technical accuracy by embedding article content in prompt
.PARAMETER Slug
    The article slug to fact-check
.PARAMETER OutputFile
    Optional file to save detailed fact-check report
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile,

    [Parameter(Mandatory=$false)]
    [string]$Model = "gemini-3-pro-preview"
)

# 1. Find Article
$BundlePath = "content/posts/$Slug/index.md"
$SingleFilePath = "content/posts/$Slug.md"

if (Test-Path $BundlePath) {
    $ArticlePath = $BundlePath
} elseif (Test-Path $SingleFilePath) {
    $ArticlePath = $SingleFilePath
} else {
    Write-Error "Article not found: $Slug" -ForegroundColor Red
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Article Fact-Check" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Article: $Slug" -ForegroundColor Yellow
Write-Host ""
Write-Host "Running fact-check (this may take 60-90 seconds)..." -ForegroundColor Yellow
Write-Host ""

try {
    # Read article content
    $ArticleContent = Get-Content $ArticlePath -Raw

    # Build fact-check prompt with article embedded
    $FactCheckPrompt = @"
Perform a comprehensive fact-check of this article. Verify accuracy and identify claims that need evidence.

FACT-CHECKING CRITERIA:

1. Technical Accuracy
   - Correct command syntax and parameters
   - Accurate API usage and method signatures
   - Valid configuration examples
   - Correct version numbers and compatibility info

2. Factual Claims
   - Performance claims (speeds, benchmarks, metrics)
   - Capacity limits (user counts, data sizes, throughput)
   - Version information and release dates
   - Feature availability and limitations

3. Best Practices
   - Security recommendations are current
   - Suggested patterns follow latest standards
   - No deprecated approaches recommended

4. Code Examples
   - Syntax is correct for specified language/version
   - Code would actually execute as claimed
   - Error handling is appropriate
   - Output examples match code logic

5. Logical Consistency
   - Article doesn't contradict itself
   - Examples support stated claims
   - Prerequisites match complexity

OUTPUT FORMAT:

# FACT-CHECK SUMMARY
- Severity: [PASS / MINOR ISSUES / MAJOR ISSUES / FAIL]
- Technical Accuracy: [0-100]%
- Factual Claims: [0-100]%
- Best Practices: [0-100]%
- Code Examples: [0-100]%
- Overall: [0-100]%

# CRITICAL ISSUES (Must Fix Before Publishing)
[List critical issues with location, problem, and correction]

# VERIFICATION NEEDED (Claims Without Evidence)
[List unverified claims that need sources or metrics]

# MINOR ISSUES (Style/Clarity Improvements)
[List minor improvements]

# CODE VALIDATION
[Validate each code block]

# RECOMMENDATIONS
1. [Priority action]
2. [Next priority]
3. [Additional improvements]

Be thorough and specific with locations and corrections.

--- ARTICLE START ---
$ArticleContent
--- ARTICLE END ---
"@

    # Call Gemini CLI
    $FactCheckResult = & gemini --yolo --model $Model $FactCheckPrompt 2>&1 | Out-String

    if ($LASTEXITCODE -ne 0) {
        throw "Gemini CLI returned exit code $LASTEXITCODE"
    }

    # Clean output
    $Lines = $FactCheckResult -split "`r?`n"
    $CleanLines = $Lines | Where-Object {
        $_ -notmatch '^Loaded cached credentials' -and
        $_ -notmatch '^Loading' -and
        $_ -notmatch '^Initializing' -and
        $_ -notmatch '^Using model' -and
        $_ -notmatch '^Gemini CLI' -and
        $_ -notmatch '^Generating content'
    }

    # Remove leading empty lines
    while ($CleanLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($CleanLines[0])) {
        $CleanLines = $CleanLines[1..($CleanLines.Count - 1)]
    }

    $FactCheckResult = ($CleanLines -join "`n").Trim()

    if ([string]::IsNullOrWhiteSpace($FactCheckResult)) {
        throw "Gemini CLI returned empty result"
    }

    Write-Host $FactCheckResult
    Write-Host ""

    # Save to file if requested
    if ($OutputFile) {
        $ReportContent = @"
# Fact-Check Report: $Slug

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Article:** $ArticlePath

---

$FactCheckResult
"@

        Set-Content -Path $OutputFile -Value $ReportContent -Encoding UTF8
        Write-Host "✓ Report saved: $OutputFile" -ForegroundColor Green
        Write-Host ""
    }

    # Parse severity
    $Severity = "UNKNOWN"
    if ($FactCheckResult -match 'Severity:\s*(PASS|MINOR ISSUES|MAJOR ISSUES|FAIL)') {
        $Severity = $Matches[1]
    }

    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan

    switch ($Severity) {
        "PASS" {
            Write-Host "  ✓ FACT-CHECK PASSED" -ForegroundColor Green
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Article is accurate and ready for publication!" -ForegroundColor Green
        }
        "MINOR ISSUES" {
            Write-Host "  ⚠ MINOR ISSUES FOUND" -ForegroundColor Yellow
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Article is mostly accurate with minor improvements needed." -ForegroundColor Yellow
        }
        "MAJOR ISSUES" {
            Write-Host "  ✗ MAJOR ISSUES FOUND" -ForegroundColor Red
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Article has significant accuracy problems." -ForegroundColor Red
            Write-Host "Fix critical issues before publishing." -ForegroundColor Yellow
        }
        "FAIL" {
            Write-Host "  ✗ FACT-CHECK FAILED" -ForegroundColor Red
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Article has critical accuracy problems." -ForegroundColor Red
            Write-Host "DO NOT publish until all issues are resolved." -ForegroundColor Red
        }
        default {
            Write-Host "  ? UNABLE TO DETERMINE SEVERITY" -ForegroundColor Yellow
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Review the fact-check results manually." -ForegroundColor Yellow
        }
    }

    Write-Host ""

} catch {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  Fact-Check Failed" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Error "Failed to run fact-check: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  - Verify Gemini CLI is working: gemini 'test'" -ForegroundColor Gray
    Write-Host "  - Check article format is valid: code $ArticlePath" -ForegroundColor Gray
    Write-Host "  - Wait 5-10 minutes for rate limits" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
