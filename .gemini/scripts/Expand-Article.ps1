<#
.SYNOPSIS
    Expand article using the defined expansion command/prompt
.DESCRIPTION
    Uses the @.gemini/commands/expand.toml template to expand an article outline
    into a full publication-ready article. Uses the Gemini model (default 3-pro)
    for full-context generation.
.PARAMETER Slug
    The article slug
.PARAMETER Mode
    [Deprecated] Legacy mode parameter (kept for compatibility)
.PARAMETER SkipBackup
    Skip backup
.PARAMETER Model
    Gemini model to use (default: gemini-3-pro-preview)
.PARAMETER DelaySeconds
    Delay between requests (if retrying)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$false)]
    [string]$Mode = 'Quality',

    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup,

    [Parameter(Mandatory=$false)]
    [string]$Model = "gemini-3-pro-preview",

    [Parameter(Mandatory=$false)]
    [int]$DelaySeconds = 10
)

function Clean-GeminiOutput {
    param([string]$RawOutput)

    $Lines = $RawOutput -split "`r?`n"
    $CleanLines = $Lines | Where-Object {
        $_ -notmatch '^(Loaded cached credentials|Loading|Initializing|Using model|Gemini CLI|Generating content|Streaming|Connected to|Attempt \d+ failed|YOLO mode is enabled)'
    }

    while ($CleanLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($CleanLines[0])) {
        $CleanLines = $CleanLines[1..($CleanLines.Count - 1)]
    }

    return ($CleanLines -join "`n").Trim()
}

function Invoke-GeminiWithRetry {
    param(
        [string]$Prompt,
        [string]$ModelName,
        [int]$MaxRetries = 3,
        [int]$BaseDelay = 10
    )

    $Attempt = 1

    while ($Attempt -le $MaxRetries) {
        try {
            $Result = & gemini --yolo --model $ModelName $Prompt 2>&1 | Out-String

            if ($Result -match '429|rate limit|quota|Resource exhausted') {
                throw "Rate limit detected"
            }

            if ($LASTEXITCODE -eq 0) {
                return Clean-GeminiOutput -RawOutput $Result
            }

            throw "Exit code $LASTEXITCODE"

        } catch {
            if ($Attempt -lt $MaxRetries) {
                $WaitTime = $BaseDelay * ([Math]::Pow(2, $Attempt - 1))
                Write-Host "  ⚠ Rate limit, waiting $($WaitTime)s (retry $($Attempt + 1)/$MaxRetries)..." -ForegroundColor Yellow
                Start-Sleep -Seconds $WaitTime
                $Attempt++
            } else {
                return $null
            }
        }
    }

    return $null
}

# 1. Find Article
$BundlePath = "content/posts/$Slug/index.md"
$SingleFilePath = "content/posts/$Slug.md"

if (Test-Path $BundlePath) {
    $ArticlePath = $BundlePath
    $BackupDir = "content/posts/$Slug/files/"
} elseif (Test-Path $SingleFilePath) {
    $ArticlePath = $SingleFilePath
    $BackupDir = "backups/"
} else {
    Write-Host "Article not found: $Slug" -ForegroundColor Red
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Article Expansion" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Article: $Slug" -ForegroundColor Yellow
Write-Host "Model:   $Model" -ForegroundColor Yellow
Write-Host ""

# 2. Load Resources
# Research
$ResearchPath = "content/posts/$Slug/files/research.md"
$ResearchContent = ""
if (Test-Path $ResearchPath) {
    $ResearchContent = Get-Content $ResearchPath -Raw
    Write-Host "✓ Found research notes" -ForegroundColor Green
} else {
    # Fallback to drafts/research if not in bundle
    $DraftResearchPath = "drafts/research/$Slug.md"
    if (Test-Path $DraftResearchPath) {
        $ResearchContent = Get-Content $DraftResearchPath -Raw
        Write-Host "✓ Found research notes (drafts)" -ForegroundColor Green
    } else {
        Write-Warning "No research notes found. Expansion will rely solely on outline."
    }
}

# Article Content (Outline)
$ArticleContent = Get-Content $ArticlePath -Raw

# 3. Backup
if (-not $SkipBackup) {
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
    $BackupFile = Join-Path $BackupDir "$Slug-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    Copy-Item $ArticlePath $BackupFile -Force
    Write-Host "✓ Backup created: $BackupFile" -ForegroundColor Green
    Write-Host ""
}

# 4. Load Command Template
$CommandPath = ".gemini/commands/expand.toml"
if (-not (Test-Path $CommandPath)) {
    Write-Error "Expand command definition not found at $CommandPath"
    exit 1
}

$CommandContent = Get-Content $CommandPath -Raw
if ($CommandContent -match '(?s)prompt\s*=\s*"""(.*?)"""') {
    $PromptTemplate = $Matches[1]
} else {
    Write-Error "Could not parse prompt from $CommandPath"
    exit 1
}

# 5. Construct Input Args
# We combine Research and Outline into the {{args}} placeholder
$InputContext = ""

if ($ResearchContent) {
    $InputContext += @"
# RESEARCH NOTES & FACTUAL BASIS
Use these facts, metrics, and technical details to ground the article:
$ResearchContent

"@
}

$InputContext += @"
# CURRENT ARTICLE OUTLINE
Expand this outline into the full article, keeping the Front Matter intact:
$ArticleContent
"@

# Replace placeholder
$FullPrompt = $PromptTemplate -replace '\{\{args\}\}', $InputContext

# 6. Execute Expansion
Write-Host "Generating full article (this may take 1-2 minutes)..." -ForegroundColor Cyan
$ExpandedContent = Invoke-GeminiWithRetry -Prompt $FullPrompt -ModelName $Model -BaseDelay $DelaySeconds

if ([string]::IsNullOrWhiteSpace($ExpandedContent)) {
    Write-Error "Expansion returned empty result."
    exit 1
}

# 7. Validation & Save
# Check if we got Front Matter back
if ($ExpandedContent -notmatch '^---') {
    Write-Warning "Generated content might be missing front matter. Attempting to restore..."
    if ($ArticleContent -match '(?s)^(---.*?---)') {
        $FrontMatter = $Matches[1]
        $ExpandedContent = $FrontMatter + "`n`n" + $ExpandedContent
    }
}

# Ensure draft: false
if ($ExpandedContent -match 'draft:\s*true') {
    $ExpandedContent = $ExpandedContent -replace 'draft:\s*true', 'draft: false'
    Write-Host "✓ Set draft status to false" -ForegroundColor Green
}

# Update Date
$Now = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
if ($ExpandedContent -match 'date:') {
     $ExpandedContent = $ExpandedContent -replace 'date:\s*[\d\-T:+Z]+', "date: $Now"
}

Set-Content -Path $ArticlePath -Value $ExpandedContent -Encoding UTF8 -NoNewline

# 8. Quality Summary
$WordCount = ($ExpandedContent -split '\s+').Count
$CodeBlocks = ([regex]::Matches($ExpandedContent, '```')).Count
$PhrasesToCheck = @('delve', 'leverage', 'robust', 'seamless', 'game-changer')
$FoundPhrases = @()
foreach ($Phrase in $PhrasesToCheck) {
    if ($ExpandedContent -match $Phrase) { $FoundPhrases += $Phrase }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Article Expansion Complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Stats:" -ForegroundColor Yellow
Write-Host "  Word Count: $WordCount" -ForegroundColor White
Write-Host "  Code Blocks: $CodeBlocks" -ForegroundColor White

if ($FoundPhrases.Count -gt 0) {
    Write-Host "  ⚠ Found banned phrases: $($FoundPhrases -join ', ')" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ No banned phrases found" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review content: code $ArticlePath" -ForegroundColor White
Write-Host "  2. Fact check:     .gemini/scripts/Test-ArticleAccuracy.ps1 -Slug $Slug" -ForegroundColor White
Write-Host ""