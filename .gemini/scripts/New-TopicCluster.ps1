<#
.SYNOPSIS
    Creates a comprehensive, strategically-driven topic cluster plan using a large language model.
.DESCRIPTION
    This script leverages a powerful Gemini model to perform in-depth research and then generate a strategic content plan, consisting of one central "Pillar Post" and multiple supporting "Cluster Posts".

    It performs two main actions:
    1.  **Research Phase:** Conducts a single, comprehensive research query to analyze the topic, audience, sub-topics, and search intent.
    2.  **Planning Phase:** Uses the research to generate a detailed content plan, outlining the title, description, audience, keywords, and questions for each article.
.PARAMETER Topic
    The broad topic to research and plan (e.g., "PowerShell Automation for DevOps").
.PARAMETER SeriesName
    A custom series name (slug) for the folder. If not provided, it's auto-generated from the topic.
.PARAMETER MinArticles
    The minimum number of supporting cluster articles to generate (default: 5).
.PARAMETER MaxArticles
    The maximum number of supporting cluster articles to generate (default: 8).
.PARAMETER Model
    The Gemini model to use for generation. Defaults to a powerful model suitable for this task.
.PARAMETER DelaySeconds
    A brief delay between the research and planning API calls to respect potential rate limits.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Topic,

    [Parameter(Mandatory=$false)]
    [string]$SeriesName,

    [Parameter(Mandatory=$false)]
    [int]$MinArticles = 5,

    [Parameter(Mandatory=$false)]
    [int]$MaxArticles = 8,

    [Parameter(Mandatory=$false)]
    [string]$Model = "gemini-3-pro-preview",

    [Parameter(Mandatory=$false)]
    [int]$DelaySeconds = 3
)

# Helper function to clean Gemini CLI output, preserving model info
function Clean-GeminiOutput {
    param([string]$RawOutput)

    # Split into lines
    $Lines = $RawOutput -split "`r?`n"

    # Filter out noisy, non-content lines but keep useful ones like model name
    $CleanLines = $Lines | Where-Object {
        $_ -notmatch '^(Loaded cached credentials|Loading|Initializing|Gemini CLI|Generating content|Streaming|Connected to)' -and
        $_.Trim() -ne ''
    }

    # Rejoin and trim
    return ($CleanLines -join "`n").Trim()
}

# Generate series slug from topic if not provided
if (-not $SeriesName) {
    $SeriesName = $Topic.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-'
}

$PlanDir = "plans/$SeriesName"
$PlanFile = "$PlanDir/_plan.md"
$ResearchFile = "$PlanDir/_research.md"
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
Write-Host "  Creating Strategic Topic Cluster Plan" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Topic: $Topic" -ForegroundColor Yellow
Write-Host "Series: $SeriesName" -ForegroundColor Yellow
Write-Host "Model: $Model" -ForegroundColor Yellow
Write-Host "Target: $MinArticles-$MaxArticles cluster articles + 1 pillar" -ForegroundColor Yellow
Write-Host ""

# Create directory structure
New-Item -ItemType Directory -Path $PlanDir -Force | Out-Null
New-Item -ItemType Directory -Path $OutlinesDir -Force | Out-Null

# --- Phase 1: Comprehensive Research ---
Write-Host "Phase 1: Conducting comprehensive research..." -ForegroundColor Green
Write-Host "──────────────────────────────────────────────" -ForegroundColor Gray

$ResearchPrompt = @"
As an expert SEO analyst and content strategist, conduct a thorough research analysis for the broad topic: "$Topic".

Your goal is to gather the necessary intelligence to create a comprehensive topic cluster (a pillar post and several supporting articles).

Provide a structured analysis in Markdown covering these areas:

1.  **Core Concepts & Definitions:** Define the topic and explain its fundamental principles.
2.  **Target Audience:** Describe the primary and secondary audiences. What are their goals, pain points, and level of expertise?
3.  **Key Sub-topics & Entities:** Identify the most important sub-topics, related concepts, and entities. These will form the basis of the cluster articles.
4.  **Common Questions & Search Intent:** List the most common questions people ask about this topic (who, what, when, where, why, how). Group them by user intent (informational, commercial, transactional).
5.  **Competitor Angle (Hypothetical):** Briefly describe 2-3 common angles or approaches competitors take when writing about this topic. What are the content gaps?

Present this research in a clear, well-organized Markdown format.
"@

try {
    Write-Host "Generating research analysis (this may take 30-90 seconds)..." -ForegroundColor Gray
    $RawResearchOutput = & gemini --yolo --model $Model $ResearchPrompt 2>&1 | Out-String
    $ResearchOutput = Clean-GeminiOutput -RawOutput $RawResearchOutput

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($ResearchOutput)) {
        throw "Research generation failed or returned empty content. Raw output: $RawResearchOutput"
    }

    $ResearchHeader = @"
# Research Analysis: $Topic

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Model:** $Model

---

"@
    $FullResearchContent = $ResearchHeader + $ResearchOutput
    Set-Content -Path $ResearchFile -Value $FullResearchContent -Encoding UTF8

    Write-Host "✓ Research complete. Analysis saved to $ResearchFile" -ForegroundColor Green
} catch {
    Write-Error "Research phase failed: $_"
    Write-Host "Aborting plan generation." -ForegroundColor Red
    exit 1
}

# Brief delay before next phase
Write-Host ""
Write-Host "  Waiting ${DelaySeconds}s before plan generation..." -ForegroundColor DarkGray
Start-Sleep -Seconds $DelaySeconds
Write-Host ""

# --- Phase 2: Strategic Plan Generation ---
Write-Host "Phase 2: Creating strategic content cluster plan..." -ForegroundColor Green
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray



try {
    Write-Host "Generating content plan (this may take 60-120 seconds)..." -ForegroundColor Gray
    $ResearchContent = Get-Content $ResearchFile -Raw
    $PlanCommand = "/plan topic:`"$Topic`" min_articles:$MinArticles max_articles:$MaxArticles"
    $FullPlanPrompt = $ResearchContent + "`n`n" + $PlanCommand
    $RawPlanOutput = & gemini --yolo --model $Model $FullPlanPrompt 2>&1 | Out-String
    $PlanOutput = Clean-GeminiOutput -RawOutput $RawPlanOutput

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($PlanOutput)) {
        throw "Plan generation failed or returned empty content. Raw output: $RawPlanOutput"
    }

    # Build plan file
    $PlanHeader = @"
# Topic Cluster Plan: $Topic

**Series Name:** $SeriesName
**Created:** $(Get-Date -Format "yyyy-MM-dd HH:mm")
**Status:** Planning
**Model:** $Model

---

"@

    $FullPlanContent = $PlanHeader + $PlanOutput
    Set-Content -Path $PlanFile -Value $FullPlanContent -Encoding UTF8

    Write-Host "✓ Plan created successfully." -ForegroundColor Green

} catch {
    Write-Error "Plan generation failed: $_"
    Write-Host ""
    Write-Host "You can try to manually create a plan later." -ForegroundColor Yellow
    Write-Host "Research is saved at: $ResearchFile" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# --- Phase 3: Finalize and Report ---
$FullPlanContent = Get-Content $PlanFile -Raw
$ArticleCount = 0

# Try to find article count from the explicit marker
if ($FullPlanContent -match 'ARTICLE_COUNT:\s*(\d+)') {
    $ArticleCount = [int]$Matches[1]
    Write-Host "✓ Found cluster article count: $ArticleCount" -ForegroundColor Green
} else {
    # Fallback: Count manually if marker is missing
    $ArticleMatches = [regex]::Matches($FullPlanContent, '\*\*Cluster Post\s+\d+:', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($ArticleMatches.Count -gt 0) {
        $ArticleCount = $ArticleMatches.Count
        Write-Host "⚠ Could not find ARTICLE_COUNT marker. Counted $ArticleCount cluster posts manually." -ForegroundColor Yellow
    } else {
        $ArticleCount = [math]::Round(($MinArticles + $MaxArticles) / 2)
        Write-Host "⚠ Could not determine article count. Using average target: $ArticleCount" -ForegroundColor Yellow
    }
}

# Add metadata to the plan file
$TotalArticles = $ArticleCount + 1 # Clusters + Pillar
$MetadataSection = @"

---

## Plan Metadata

- **Pillar Articles:** 1
- **Cluster Articles:** $ArticleCount
- **Total Articles:** $TotalArticles
- **Target Range:** $MinArticles-$MaxArticles cluster articles

---

"@

# Inject metadata after the first '---'
$FinalContent = $FullPlanContent -replace '(---\s*[\r\n]+)', "`$1$MetadataSection"
Set-Content -Path $PlanFile -Value $FinalContent -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Topic Cluster Plan Created Successfully!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files Created:" -ForegroundColor Yellow
Write-Host "  Research: $ResearchFile" -ForegroundColor Gray
Write-Host "  Plan:     $PlanFile" -ForegroundColor Gray
Write-Host ""
Write-Host "Article Count: 1 Pillar Post + $ArticleCount Cluster Posts" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review the strategic plan:   code $PlanFile" -ForegroundColor White
Write-Host "  2. Generate individual outlines:  .\scripts\Generate-Outlines.ps1 -SeriesName $SeriesName" -ForegroundColor White
Write-Host ""
