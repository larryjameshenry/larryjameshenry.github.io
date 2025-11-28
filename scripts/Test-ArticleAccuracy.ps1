<#
.SYNOPSIS
    Fact-check an article using Gemini CLI
.DESCRIPTION
    Uses Gemini CLI /factcheck command to verify technical accuracy
.PARAMETER Slug
    The article slug to fact-check
.PARAMETER OutputFile
    Optional file to save detailed fact-check report
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

# Logic to determine path: check for bundle first, then standalone file
$BundlePath = "content/posts/$Slug/index.md"
$StandalonePath = "content/posts/$Slug.md"

if (Test-Path $BundlePath) {
    $ArticlePath = $BundlePath
    Write-Host "Fact-checking bundle: $ArticlePath" -ForegroundColor Gray
} elseif (Test-Path $StandalonePath) {
    $ArticlePath = $StandalonePath
    Write-Host "Fact-checking file: $ArticlePath" -ForegroundColor Gray
} else {
    Write-Error "Article not found: $Slug"
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Article Fact-Check" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Article: $Slug" -ForegroundColor Yellow
Write-Host ""
Write-Host "Running fact-check..." -ForegroundColor Yellow
Write-Host ""

try {
    # Use /factcheck command from TOML
    $FactCheckResult = Get-Content $ArticlePath -Raw | gemini "/factcheck"

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

        $ReportContent | Out-File $OutputFile -Encoding UTF8
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
        }
        "MINOR ISSUES" {
            Write-Host "  ⚠ MINOR ISSUES FOUND" -ForegroundColor Yellow
        }
        { $_ -in @("MAJOR ISSUES", "FAIL") } {
            Write-Host "  ✗ CRITICAL ISSUES FOUND" -ForegroundColor Red
        }
    }

    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

} catch {
    Write-Error "Failed to run fact-check: $_"
    exit 1
}
