<#
.SYNOPSIS
    Create a comprehensive topic cluster plan for a broad subject
.DESCRIPTION
    Uses Gemini CLI with incremental research to avoid rate limits.
    Filters out debug messages from Gemini CLI output.
.PARAMETER Topic
    The broad topic to research and plan (e.g., "PowerShell Automation")
.PARAMETER SeriesName
    Optional custom series name (auto-generated from topic if not provided)
.PARAMETER MinArticles
    Minimum number of articles to generate (default: 5)
.PARAMETER MaxArticles
    Maximum number of articles to generate (default: 8)
.PARAMETER DelaySeconds
    Delay between API calls in seconds (default: 3)
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
    [int]$DelaySeconds = 3
)

# Helper function to clean Gemini CLI output
function Clean-GeminiOutput {
    param([string]$RawOutput)

    # Split into lines
    $Lines = $RawOutput -split "`r?`n"

    # Filter out debug/status messages
    $CleanLines = $Lines | Where-Object {
        $_ -notmatch '^Loaded cached credentials' -and
        $_ -notmatch '^Loading' -and
        $_ -notmatch '^Initializing' -and
        $_ -notmatch '^Using model' -and
        $_ -notmatch '^Gemini CLI' -and
        $_ -notmatch '^\s*$' -and  # Skip empty lines at start
        $_ -notmatch '^Generating content' -and
        $_ -notmatch '^Streaming' -and
        $_ -notmatch '^Connected to'
    }

    # Rejoin and trim
    $CleanOutput = ($CleanLines -join "`n").Trim()

    return $CleanOutput
}

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
Write-Host "  Creating Topic Cluster Plan (Incremental Mode)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Topic: $Topic" -ForegroundColor Yellow
Write-Host "Series: $SeriesName" -ForegroundColor Yellow
Write-Host "Target: $MinArticles-$MaxArticles articles" -ForegroundColor Yellow
Write-Host "Rate Limit Protection: ${DelaySeconds}s delays between requests" -ForegroundColor Yellow
Write-Host ""

# Create directory structure
New-Item -ItemType Directory -Path $PlanDir -Force | Out-Null
New-Item -ItemType Directory -Path $OutlinesDir -Force | Out-Null

Write-Host "Phase 1: Incremental research (5 focused queries)..." -ForegroundColor Green
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray

$ResearchFile = "$PlanDir/_research.md"

# Break research into smaller, focused queries
$ResearchQueries = @(
    @{
        Name = "Overview"
        Prompt = "Provide a concise overview of $Topic including: definition, why it matters, and current relevance in 2024. Keep response under 300 words."
    },
    @{
        Name = "Key Concepts"
        Prompt = "List and briefly explain the 5-7 most important concepts or components related to $Topic. Keep response under 300 words."
    },
    @{
        Name = "Practical Applications"
        Prompt = "Describe 3-4 common real-world use cases or applications of $Topic. Keep response under 300 words."
    },
    @{
        Name = "Best Practices"
        Prompt = "List 5-7 best practices, tips, or common patterns for $Topic. Keep response under 300 words."
    },
    @{
        Name = "Common Challenges"
        Prompt = "Describe 3-5 common challenges, pitfalls, or problems people encounter with $Topic. Keep response under 300 words."
    }
)

# Initialize research file
$ResearchContent = @"
# Research: $Topic

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

---

"@

# Execute each research query with delays
$QueryNumber = 1
foreach ($Query in $ResearchQueries) {
    Write-Host "  [$QueryNumber/$($ResearchQueries.Count)] Researching: $($Query.Name)..." -ForegroundColor Cyan

    try {
        # Capture raw output
        $RawResult = & gemini $Query.Prompt 2>&1 | Out-String

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Query failed, using placeholder for: $($Query.Name)"
            $Result = "[Research pending for $($Query.Name)]"
        } else {
            # Clean the output
            $Result = Clean-GeminiOutput -RawOutput $RawResult

            if ([string]::IsNullOrWhiteSpace($Result)) {
                Write-Warning "Empty result after cleaning, using placeholder"
                $Result = "[Research pending for $($Query.Name)]"
            }
        }

        # Append to research content
        $ResearchContent += @"

## $($Query.Name)

$Result

"@

        Write-Host "    ✓ Complete ($($Result.Length) chars)" -ForegroundColor Green

        # Delay before next request (except for last one)
        if ($QueryNumber -lt $ResearchQueries.Count) {
            Write-Host "    Waiting ${DelaySeconds}s to avoid rate limits..." -ForegroundColor DarkGray
            Start-Sleep -Seconds $DelaySeconds
        }

    } catch {
        Write-Warning "Error in research query: $_"
        $ResearchContent += @"

## $($Query.Name)

[Error retrieving information]

"@
    }

    $QueryNumber++
}

# Save research file
Set-Content -Path $ResearchFile -Value $ResearchContent -Encoding UTF8
Write-Host ""
Write-Host "✓ Research complete and saved" -ForegroundColor Green

# Verify research file is valid
$VerifyResearch = Get-Content $ResearchFile -Raw
if ($VerifyResearch -match 'Loaded cached credentials' -or $VerifyResearch.Length -lt 500) {
    Write-Warning "Research file may have issues. Review: $ResearchFile"
    Write-Host "Content preview:" -ForegroundColor Yellow
    Write-Host ($VerifyResearch.Substring(0, [Math]::Min(300, $VerifyResearch.Length))) -ForegroundColor Gray
}

# Delay before plan generation
Write-Host "  Waiting ${DelaySeconds}s before plan generation..." -ForegroundColor DarkGray
Start-Sleep -Seconds $DelaySeconds

Write-Host ""
Write-Host "Phase 2: Creating strategic content cluster plan..." -ForegroundColor Green
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray

# Simplified plan prompt to reduce token count
$PlanPrompt = @"
Based on the research context, create a content plan for: $Topic

Generate $MinArticles to $MaxArticles supporting articles (plus 1 pillar).

Start your response with: ARTICLE_COUNT: [number]

Then for each article provide:
**Article [N]: [Title]**
- Description: [1-2 sentences]
- Key points: [3 bullet points]
- Keywords: [3-4 keywords]

Keep the plan concise and focused.
"@

try {
    Write-Host "Generating plan structure (this may take 30-60 seconds)..." -ForegroundColor Gray

    # Capture and clean output
    $RawPlanOutput = & gemini "--add" $ResearchFile $PlanPrompt 2>&1 | Out-String
    $PlanOutput = Clean-GeminiOutput -RawOutput $RawPlanOutput

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($PlanOutput)) {
        Write-Host "Plan generation had issues, trying without research context..." -ForegroundColor Yellow
        Start-Sleep -Seconds $DelaySeconds

        $SimplePlanPrompt = @"
Create a simple content plan for $MinArticles to $MaxArticles articles about: $Topic

Start with: ARTICLE_COUNT: [number]

Then list each article:
**Article [N]: [Title]**
- Description: [brief description]
- Key topics: [3 points]
"@

        $RawPlanOutput = & gemini $SimplePlanPrompt 2>&1 | Out-String
        $PlanOutput = Clean-GeminiOutput -RawOutput $RawPlanOutput
    }

    # Verify we got actual content
    if ([string]::IsNullOrWhiteSpace($PlanOutput) -or $PlanOutput.Length -lt 100) {
        throw "Plan output is too short or empty after cleaning"
    }

    # Build plan file
    $PlanHeader = @"
# Topic Cluster Plan: $Topic

**Series Name:** $SeriesName
**Created:** $(Get-Date -Format "yyyy-MM-dd HH:mm")
**Status:** Planning

---

"@

    $FullPlanContent = $PlanHeader + $PlanOutput
    Set-Content -Path $PlanFile -Value $FullPlanContent -Encoding UTF8

    Write-Host "✓ Plan created" -ForegroundColor Green

} catch {
    Write-Error "Plan generation failed: $_"
    Write-Host ""
    Write-Host "You can manually edit the research and create a plan later." -ForegroundColor Yellow
    Write-Host "Research saved at: $ResearchFile" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# Parse article count
$FullPlanContent = Get-Content $PlanFile -Raw
$ArticleCount = 0

# Try to find article count
if ($FullPlanContent -match 'ARTICLE_COUNT:\s*(\d+)') {
    $ArticleCount = [int]$Matches[1]
} else {
    # Count manually
    $ArticleMatches = [regex]::Matches($FullPlanContent, '\*\*Article\s+(\d+):', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($ArticleMatches.Count -gt 0) {
        $ArticleCount = ($ArticleMatches | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
    }
}

if ($ArticleCount -eq 0) {
    $ArticleCount = [math]::Round(($MinArticles + $MaxArticles) / 2)
    Write-Host "⚠ Using default article count: $ArticleCount" -ForegroundColor Yellow
} else {
    Write-Host "✓ Found article count: $ArticleCount" -ForegroundColor Green
}

# Add metadata
$MetadataSection = @"

---

## Plan Metadata

- **Article Count:** $ArticleCount
- **Target Range:** $MinArticles-$MaxArticles articles
- **Includes:** 1 pillar article + $ArticleCount supporting articles

---

"@

$UpdatedContent = $FullPlanContent -replace '(---\s*[\r\n]+[\r\n]+)', "`$1$MetadataSection"
Set-Content -Path $PlanFile -Value $UpdatedContent -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Topic Cluster Plan Created Successfully!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files Created:" -ForegroundColor Yellow
Write-Host "  Research: $ResearchFile" -ForegroundColor Gray
Write-Host "  Plan: $PlanFile" -ForegroundColor Gray
Write-Host ""
Write-Host "Article Count: $ArticleCount supporting articles + 1 pillar" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review the plan:     code $PlanFile" -ForegroundColor White
Write-Host "  2. Generate outlines:   .\scripts\Generate-Outlines.ps1 -SeriesName $SeriesName -DelaySeconds $DelaySeconds" -ForegroundColor White
Write-Host ""
Write-Host "Note: Using -DelaySeconds parameter to respect rate limits" -ForegroundColor Yellow
Write-Host ""
