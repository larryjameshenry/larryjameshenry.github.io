<#
.SYNOPSIS
    Generate individual article outlines from a topic cluster plan
.DESCRIPTION
    Reads the topic cluster plan and generates individual outline markdown files
    for each article with proper Hugo front matter and taxonomy linking
.PARAMETER SeriesName
    The series/plan name (folder name under plans/)
.PARAMETER Count
    Optional: Number of outlines to generate (default: read from plan metadata)
.PARAMETER IncludePillar
    Include the pillar article in outline generation
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SeriesName,

    [Parameter(Mandatory=$false)]
    [int]$Count = 0,

    [Parameter(Mandatory=$false)]
    [switch]$IncludePillar
)

$PlanDir = Resolve-Path "plans/$SeriesName" | Select-Object -ExpandProperty Path
$PlanFile = "$PlanDir\_plan.md"
$OutlinesDir = "$PlanDir\outlines"

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

# Method 1: Try to read article count from metadata
$TotalArticles = 0
if ($PlanContent -match '\*\*Article Count:\*\*\s*(\d+)') {
    $TotalArticles = [int]$Matches[1]
    Write-Host "✓ Found article count in metadata: $TotalArticles" -ForegroundColor Green
}

# Method 2: Look for explicit ARTICLE_COUNT marker
if ($TotalArticles -eq 0 -and $PlanContent -match 'ARTICLE_COUNT:\s*(\d+)') {
    $TotalArticles = [int]$Matches[1]
    Write-Host "✓ Found explicit article count marker: $TotalArticles" -ForegroundColor Green
}

# Method 3: Ask Gemini to count articles
if ($TotalArticles -eq 0) {
    Write-Host "⚠ Article count not found in metadata, asking Gemini..." -ForegroundColor Yellow

    $CountPrompt = "Count the number of supporting articles in this plan (exclude pillar). Respond with ONLY a number."
    $CountResult = Get-Content $PlanFile -Raw | gemini "$CountPrompt"

    if ($CountResult -match '(\d+)') {
        $TotalArticles = [int]$Matches[1]
        Write-Host "✓ Gemini counted: $TotalArticles articles" -ForegroundColor Green
    }
}

# Method 4: Fallback pattern matching
if ($TotalArticles -eq 0) {
    Write-Host "⚠ Using fallback pattern matching..." -ForegroundColor Yellow

    $Patterns = @(
        '\*\*Article\s+(\d+):',
        '(?:^|\n)#{2,3}\s+Article\s+(\d+)[.:]'
    )

    foreach ($Pattern in $Patterns) {
        $Matches = [regex]::Matches($PlanContent, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

        if ($Matches.Count -gt 0) {
            $TotalArticles = ($Matches | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
            Write-Host "✓ Counted $TotalArticles articles using pattern matching" -ForegroundColor Green
            break
        }
    }
}

# Final fallback
if ($TotalArticles -eq 0) {
    Write-Error "Could not determine article count from plan."
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  - Specify manually: -Count [number]" -ForegroundColor Gray
    Write-Host "  - Regenerate plan: .\scripts\New-TopicCluster.ps1" -ForegroundColor Gray
    exit 1
}

# Use specified count if provided
if ($Count -gt 0) {
    Write-Host "Using specified count: $Count (detected: $TotalArticles)" -ForegroundColor Yellow
    $TotalArticles = $Count
}

Write-Host ""
Write-Host "Plan: $SeriesName" -ForegroundColor Yellow
Write-Host "Articles to Generate: $TotalArticles" -ForegroundColor Yellow
Write-Host ""

# Generate pillar article if requested
if ($IncludePillar) {
    Write-Host "Generating Pillar Article outline..." -ForegroundColor Green
    Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray

    $PillarFile = "$OutlinesDir/00-pillar.md"

    # Use /breakdown command with pillar-specific instruction
    Get-Content $PlanFile -Raw | gemini "/breakdown Pillar Article" | Out-File $PillarFile -Encoding UTF8

    Write-Host "✓ Pillar article outline created: $PillarFile" -ForegroundColor Green
    Write-Host ""
}

# Generate supporting article outlines using /breakdown command
for ($i = 1; $i -le $TotalArticles; $i++) {
    $OutlineFile = "$OutlinesDir/{0:D2}-article-{0}.md" -f $i

    Write-Host "Generating outline $i of ${TotalArticles}..." -ForegroundColor Green
    Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray

    # Use /breakdown command from TOML - it has the full prompt logic
    Get-Content $PlanFile -Raw | gemini "/breakdown Article $i" | Out-File $OutlineFile -Encoding UTF8

    Write-Host "✓ Outline $i created: $OutlineFile" -ForegroundColor Green
    Write-Host ""

    # Brief pause to avoid rate limiting
    if ($i -lt $TotalArticles) {
        Start-Sleep -Seconds 2
    }
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  All Outlines Generated!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Outlines Location: $OutlinesDir" -ForegroundColor Yellow
Write-Host "Files Created: $($TotalArticles + $(if($IncludePillar){1}else{0}))" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review outlines:        code $OutlinesDir" -ForegroundColor White
Write-Host "  2. Edit/refine as needed" -ForegroundColor White
Write-Host "  3. Promote to content:     .\scripts\Promote-Outline.ps1 -SeriesName $SeriesName -Number 1" -ForegroundColor White
Write-Host "  4. Expand to full article: .\scripts\Expand-Article.ps1 -Slug [article-slug]" -ForegroundColor White
Write-Host ""
