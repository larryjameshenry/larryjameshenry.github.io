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
.PARAMETER MinArticles
    Minimum number of articles to generate (default: 8)
.PARAMETER MaxArticles
    Maximum number of articles to generate (default: 12)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Topic,

    [Parameter(Mandatory=$false)]
    [string]$SeriesName,

    [Parameter(Mandatory=$false)]
    [int]$MinArticles = 8,

    [Parameter(Mandatory=$false)]
    [int]$MaxArticles = 12
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
Write-Host "Target: $MinArticles-$MaxArticles articles" -ForegroundColor Yellow
Write-Host ""

# Create directory structure
New-Item -ItemType Directory -Path $PlanDir -Force | Out-Null
New-Item -ItemType Directory -Path $OutlinesDir -Force | Out-Null

Write-Host "Phase 1: Deep research on broad topic..." -ForegroundColor Green
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray

# Use /research command from TOML
$ResearchFile = "$PlanDir/_research.md"
Write-Output "# Research: $Topic" | Out-File $ResearchFile -Encoding UTF8
Write-Output "" | Out-File $ResearchFile -Append -Encoding UTF8
gemini "/research $Topic" | Out-File $ResearchFile -Append -Encoding UTF8

Write-Host "✓ Research complete" -ForegroundColor Green
Write-Host ""
Write-Host "Phase 2: Creating strategic content cluster plan..." -ForegroundColor Green
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray

# Build arguments for /plan command
$PlanArgs = "$Topic (target: $MinArticles-$MaxArticles articles)"

# Generate topic cluster plan using /plan command from TOML
$PlanHeader = @"
# Topic Cluster Plan: $Topic

**Series Name:** $SeriesName
**Created:** $(Get-Date -Format "yyyy-MM-dd HH:mm")
**Status:** Planning

---

"@

Write-Output $PlanHeader | Out-File $PlanFile -Encoding UTF8
Get-Content $ResearchFile -Raw | gemini "/plan $PlanArgs" | Out-File $PlanFile -Append -Encoding UTF8

Write-Host "✓ Strategic plan created" -ForegroundColor Green
Write-Host ""

# Parse the article count from the plan
$FullPlanContent = Get-Content $PlanFile -Raw

# Method 1: Look for explicit ARTICLE_COUNT marker
$ArticleCount = 0
if ($FullPlanContent -match 'ARTICLE_COUNT:\s*(\d+)') {
    $ArticleCount = [int]$Matches[1]
    Write-Host "✓ Found explicit article count: $ArticleCount" -ForegroundColor Green
}

# Method 2: If no explicit count, ask Gemini to count the articles
if ($ArticleCount -eq 0) {
    Write-Host "⚠ No explicit article count found, asking Gemini to count..." -ForegroundColor Yellow

    $CountPrompt = @"
Count how many supporting articles are in this content plan (exclude the pillar article).
Look for patterns like "Article 1:", "Article 2:", etc.
Respond with ONLY a number, nothing else.
"@

    $CountResult = Get-Content $PlanFile -Raw | gemini "$CountPrompt"
    if ($CountResult -match '(\d+)') {
        $ArticleCount = [int]$Matches[1]
        Write-Host "✓ Gemini counted: $ArticleCount articles" -ForegroundColor Green
    }
}

# Method 3: Fallback - manual regex counting
if ($ArticleCount -eq 0) {
    Write-Host "⚠ Using fallback counting method..." -ForegroundColor Yellow

    $ArticleMatches = [regex]::Matches($FullPlanContent, '\*\*Article\s+(\d+):', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    if ($ArticleMatches.Count -gt 0) {
        $ArticleCount = ($ArticleMatches | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
        Write-Host "✓ Counted by pattern matching: $ArticleCount articles" -ForegroundColor Green
    }
}

# If still no count, use default
if ($ArticleCount -eq 0) {
    $ArticleCount = [math]::Round(($MinArticles + $MaxArticles) / 2)
    Write-Host "⚠ Could not determine count, using default: $ArticleCount articles" -ForegroundColor Yellow
}

# Update the plan file with the article count metadata
$MetadataSection = @"

---

## Plan Metadata

- **Article Count:** $ArticleCount
- **Target Range:** $MinArticles-$MaxArticles articles
- **Includes:** 1 pillar article + $ArticleCount supporting articles

---

"@

$UpdatedContent = $FullPlanContent -replace '(---\s*\r?\n\r?\n)', "`$1$MetadataSection"
$UpdatedContent | Out-File $PlanFile -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Topic Cluster Plan Created Successfully!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Plan Location: $PlanFile" -ForegroundColor Yellow
Write-Host "Article Count: $ArticleCount supporting articles + 1 pillar" -ForegroundColor Yellow
Write-Host "Total Articles: $($ArticleCount + 1)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review the plan:     code $PlanFile" -ForegroundColor White
Write-Host "  2. Generate outlines:   .\scripts\Generate-Outlines.ps1 -SeriesName $SeriesName" -ForegroundColor White
Write-Host "  3. Review outlines:     code $OutlinesDir" -ForegroundColor White
Write-Host ""
