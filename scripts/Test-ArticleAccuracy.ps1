<#
.SYNOPSIS
    Fact-check an article using Gemini CLI
.DESCRIPTION
    Uses Gemini CLI to verify technical accuracy, check claims, validate code,
    and identify statements that need evidence or correction
.PARAMETER Slug
    The article slug to fact-check
.PARAMETER OutputFile
    Optional file to save detailed fact-check report
.PARAMETER AutoFix
    Attempt to automatically apply suggested corrections (use with caution)
.EXAMPLE
    .\scripts\Test-ArticleAccuracy.ps1 -Slug "powershell-automation-basics"
.EXAMPLE
    .\scripts\Test-ArticleAccuracy.ps1 -Slug "azure-pipelines" -OutputFile "factcheck-azure.md"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile,

    [Parameter(Mandatory=$false)]
    [switch]$AutoFix
)

$ArticlePath = "content/posts/$Slug.md"

if (-not (Test-Path $ArticlePath)) {
    Write-Error "Article not found: $ArticlePath"
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Article Fact-Check" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Article: $Slug" -ForegroundColor Yellow
Write-Host "Path: $ArticlePath" -ForegroundColor Gray
Write-Host ""
Write-Host "Running comprehensive fact-check..." -ForegroundColor Yellow
Write-Host "This may take 30-60 seconds..." -ForegroundColor Gray
Write-Host ""

try {
    # Run fact-check command
    $FactCheckResult = gemini --add $ArticlePath "/factcheck"

    if ([string]::IsNullOrWhiteSpace($FactCheckResult)) {
        throw "Gemini CLI returned empty result"
    }

    # Display results
    Write-Host $FactCheckResult
    Write-Host ""

    # Save to file if requested
    if ($OutputFile) {
        $ReportPath = if ([System.IO.Path]::IsPathRooted($OutputFile)) {
            $OutputFile
        } else {
            Join-Path (Get-Location) $OutputFile
        }

        $ReportContent = @"
# Fact-Check Report: $Slug

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Article:** $ArticlePath

---

$FactCheckResult
"@

        $ReportContent | Out-File $ReportPath -Encoding UTF8
        Write-Host "✓ Detailed report saved: $ReportPath" -ForegroundColor Green
        Write-Host ""
    }

    # Parse severity from result
    $Severity = "UNKNOWN"
    if ($FactCheckResult -match 'Severity:\s*(PASS|MINOR ISSUES|MAJOR ISSUES|FAIL)') {
        $Severity = $Matches[1]
    }

    # Display summary based on severity
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
            Write-Host "Review suggestions above and apply corrections." -ForegroundColor Gray
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
    Write-Host "Next Steps:" -ForegroundColor Cyan

    if ($Severity -in @("MAJOR ISSUES", "FAIL")) {
        Write-Host "  1. Review critical issues in detail above" -ForegroundColor White
        Write-Host "  2. Make corrections to: $ArticlePath" -ForegroundColor White
        Write-Host "  3. Re-run fact-check: .\scripts\Test-ArticleAccuracy.ps1 -Slug $Slug" -ForegroundColor White
        Write-Host "  4. Only publish after PASS or MINOR ISSUES status" -ForegroundColor White
    } elseif ($Severity -eq "MINOR ISSUES") {
        Write-Host "  1. Review and apply suggested improvements" -ForegroundColor White
        Write-Host "  2. Optional: Re-run fact-check to verify" -ForegroundColor White
        Write-Host "  3. Proceed with publishing when ready" -ForegroundColor White
    } else {
        Write-Host "  1. Proceed with expansion or publishing" -ForegroundColor White
        Write-Host "  2. Consider final polish: gemini --add $ArticlePath '/finalize'" -ForegroundColor White
    }

    Write-Host ""

} catch {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  Fact-Check Failed" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Error "Failed to run fact-check: $_"
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  - Verify Gemini CLI is configured: gemini config" -ForegroundColor Gray
    Write-Host "  - Check article format is valid" -ForegroundColor Gray
    Write-Host "  - Try manual fact-check: gemini --add $ArticlePath '/factcheck'" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
