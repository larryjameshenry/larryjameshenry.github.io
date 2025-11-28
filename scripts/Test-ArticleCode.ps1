<#
.SYNOPSIS
    Test all code examples in an article
.DESCRIPTION
    Uses Gemini CLI /testcode command to validate code syntax and logic
.PARAMETER Slug
    The article slug to test
.PARAMETER OutputFile
    Optional file to save test results
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
    Write-Host "Testing code in bundle: $ArticlePath" -ForegroundColor Gray
} elseif (Test-Path $StandalonePath) {
    $ArticlePath = $StandalonePath
    Write-Host "Testing code in file: $ArticlePath" -ForegroundColor Gray
} else {
    Write-Error "Article not found: $Slug"
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Code Validation Test" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Article: $Slug" -ForegroundColor Yellow
Write-Host ""

# Use /testcode command from TOML
Write-Host "Running code validation..." -ForegroundColor Yellow
$TestResult = Get-Content $ArticlePath -Raw | gemini "/testcode"

Write-Host $TestResult
Write-Host ""

# Save results if requested
if ($OutputFile) {
    $ReportContent = @"
# Code Validation Report: $Slug

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Article:** $ArticlePath

---

$TestResult
"@

    $ReportContent | Out-File $OutputFile -Encoding UTF8
    Write-Host "✓ Test results saved: $OutputFile" -ForegroundColor Green
    Write-Host ""
}
