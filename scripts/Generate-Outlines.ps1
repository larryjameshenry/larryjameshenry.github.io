<#
.SYNOPSIS
    Generate individual article outlines from a topic cluster plan
.DESCRIPTION
    Reads the topic cluster plan and generates individual outline markdown files
    for each article with proper Hugo front matter and taxonomy linking
.PARAMETER SeriesName
    The series/plan name (folder name under plans/)
.PARAMETER Count
    Optional: Number of outlines to generate (default: all from plan)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SeriesName,

    [Parameter(Mandatory=$false)]
    [int]$Count = 0
)

$PlanDir = "plans/$SeriesName"
$PlanFile = "$PlanDir/_plan.md"
$OutlinesDir = "$PlanDir/outlines"

if (-not (Test-Path $PlanFile)) {
    Write-Error "Plan file not found: $PlanFile"
    Write-Host "Create a plan first: .\scripts\New-TopicCluster.ps1 -Topic 'Your Topic'" -ForegroundColor Yellow
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Generating Article Outlines" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Read plan content
$PlanContent = Get-Content $PlanFile -Raw

# Parse plan to find article count (rough pattern matching)
$ArticleMatches = [regex]::Matches($PlanContent, "(?:Article|^\d+\.)\s+(\d+):", [System.Text.RegularExpressions.RegexOptions]::Multiline)
$TotalArticles = if ($ArticleMatches.Count -gt 0) {
    ($ArticleMatches | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
} else {
    # Fallback: count major sections that look like articles
    ([regex]::Matches($PlanContent, "^#{2,3}\s+(?:Article|\d+)", [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
}

if ($TotalArticles -eq 0) {
    Write-Error "Could not determine article count from plan. Please check plan format."
    exit 1
}

if ($Count -eq 0 -or $Count -gt $TotalArticles) {
    $Count = $TotalArticles
}

Write-Host "Plan: $SeriesName" -ForegroundColor Yellow
Write-Host "Total Articles: $TotalArticles" -ForegroundColor Yellow
Write-Host "Generating: $Count outlines" -ForegroundColor Yellow
Write-Host ""

# Generate each outline
for ($i = 1; $i -le $Count; $i++) {
    $OutlineFile = "$OutlinesDir/{0:D2}-article-{0}.md" -f $i

    Write-Host "Generating outline $i of ${Count}..." -ForegroundColor Green
    Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray

    # Generate outline using plan context
    gemini --add $PlanFile "/breakdown Article $i" | Out-File $OutlineFile -Encoding UTF8

    Write-Host "✓ Outline $i created: $OutlineFile" -ForegroundColor Green
    Write-Host ""

    # Brief pause to avoid rate limiting
    if ($i -lt $Count) {
        Start-Sleep -Seconds 2
    }
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  All Outlines Generated!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Outlines Location: $OutlinesDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review outlines:        code $OutlinesDir" -ForegroundColor White
Write-Host "  2. Edit/refine as needed" -ForegroundColor White
Write-Host "  3. Promote to content:     .\scripts\Promote-Outline.ps1 -SeriesName $SeriesName -Number 1" -ForegroundColor White
Write-Host "  4. Expand to full article: .\scripts\Expand-Article.ps1 -Slug [article-slug]" -ForegroundColor White
Write-Host ""
