<#
.SYNOPSIS
    Create a comprehensive topic cluster plan for a broad subject
.DESCRIPTION
    Uses Gemini CLI to research a broad topic and create a strategic plan
    for a series of interconnected articles (pillar + supporting articles)
.PARAMETER Topic
    The broad topic to research and plan (e.g., "PowerShell Automation")
.PARAMETER SeriesName
    Optional custom series name (auto-generated from topic if not provided)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Topic,

    [Parameter(Mandatory=$false)]
    [string]$SeriesName
)

# Generate series slug from topic if not provided
if (-not $SeriesName) {
    $SeriesName = $Topic.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-'
}

$PlanDir = "plans/$SeriesName"
$PlanFile = "$PlanDir/_plan.md"
$OutlinesDir = "$PlanDir/outlines"

# Check if plan already exists
if (Test-Path $PlanFile) {
    Write-Warning "Topic cluster plan already exists at: $PlanFile"
    $Confirm = Read-Host "Overwrite existing plan? (y/n)"
    if ($Confirm -ne 'y') {
        exit 0
    }
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Creating Topic Cluster Plan" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Topic: $Topic" -ForegroundColor Yellow
Write-Host "Series: $SeriesName" -ForegroundColor Yellow
Write-Host ""

# Create directory structure
New-Item -ItemType Directory -Path $PlanDir -Force | Out-Null
New-Item -ItemType Directory -Path $OutlinesDir -Force | Out-Null

Write-Host "Phase 1: Deep research on broad topic..." -ForegroundColor Green
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray

# Research the broad topic
$ResearchFile = "$PlanDir/_research.md"
Write-Output "# Research: $Topic" | Out-File $ResearchFile -Encoding UTF8
Write-Output "" | Out-File $ResearchFile -Append -Encoding UTF8
gemini "/research $Topic" | Out-File $ResearchFile -Append -Encoding UTF8

Write-Host "✓ Research complete" -ForegroundColor Green
Write-Host ""
Write-Host "Phase 2: Creating strategic content cluster plan..." -ForegroundColor Green
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray

# Generate topic cluster plan using research
$PlanHeader = @"
# Topic Cluster Plan: $Topic

**Series Name:** $SeriesName
**Created:** $(Get-Date -Format "yyyy-MM-dd HH:mm")
**Status:** Planning

---

"@

Write-Output $PlanHeader | Out-File $PlanFile -Encoding UTF8
gemini --add $ResearchFile "/plan $Topic" | Out-File $PlanFile -Append -Encoding UTF8

Write-Host "✓ Strategic plan created" -ForegroundColor Green
Write-Host ""

# Parse the plan to count articles (rough estimate)
$PlanContent = Get-Content $PlanFile -Raw
$ArticleCount = ([regex]::Matches($PlanContent, "Article \d+:|^\d+\.", [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Topic Cluster Plan Created Successfully!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Plan Location: $PlanFile" -ForegroundColor Yellow
Write-Host "Estimated Articles: ~$ArticleCount articles" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review the plan:     code $PlanFile" -ForegroundColor White
Write-Host "  2. Generate outlines:   .\scripts\Generate-Outlines.ps1 -SeriesName $SeriesName" -ForegroundColor White
Write-Host "  3. Review outlines:     code $OutlinesDir" -ForegroundColor White
Write-Host ""
