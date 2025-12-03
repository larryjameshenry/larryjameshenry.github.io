<#
.SYNOPSIS
    Research an article topic/outline using the Gemini 'research' command template.
.DESCRIPTION
    Reads the article outline, applies the research prompt from .gemini/commands/research.toml,
    and saves the result to drafts/research.
.PARAMETER Slug
    The article slug
.PARAMETER DelaySeconds
    Delay between requests (if retrying)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$false)]
    [int]$DelaySeconds = 10,

    [Parameter(Mandatory=$false)]
    [string]$Model = "gemini-3-pro-preview"
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
            # Using --yolo for direct execution without confirmation
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

# 1. Find Article (Outline source)
$BundlePath = "content/posts/$Slug/index.md"
$SingleFilePath = "content/posts/$Slug.md"

if (Test-Path $BundlePath) {
    $ArticlePath = $BundlePath
} elseif (Test-Path $SingleFilePath) {
    $ArticlePath = $SingleFilePath
} else {
    Write-Host "Article not found: $Slug" -ForegroundColor Red
    exit 1
}

Write-Host "Source: $ArticlePath" -ForegroundColor Gray

# 2. Extract Outline Content
$CurrentContent = Get-Content $ArticlePath -Raw
$OutlineContent = $CurrentContent

# Remove Front Matter
if ($CurrentContent -match '(?s)^(---.*?---)\s*(.*)') {
    $OutlineContent = $Matches[2].Trim()
}

# 3. Read Research Command Template
$CommandPath = ".gemini/commands/research.toml"
if (-not (Test-Path $CommandPath)) {
    Write-Host "Research command definition not found at $CommandPath" -ForegroundColor Red
    exit 1
}

# Parse TOML-ish file manually to get the prompt (avoiding dependencies)
$CommandContent = Get-Content $CommandPath -Raw
# Extract text inside triple quotes for 'prompt = """ ... """'
if ($CommandContent -match '(?s)prompt\s*=\s*"""(.*?)"""') {
    $PromptTemplate = $Matches[1]
} else {
    Write-Host "Could not parse prompt from $CommandPath" -ForegroundColor Red
    exit 1
}

# 4. Construct Prompt
$Prompt = $PromptTemplate -replace '\{\{args\}\}', $OutlineContent

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Researching Article: $Slug" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 5. Run Gemini
Write-Host "Sending research request..." -ForegroundColor Yellow
$ResearchResult = Invoke-GeminiWithRetry -Prompt $Prompt -ModelName $Model -BaseDelay $DelaySeconds

if ([string]::IsNullOrWhiteSpace($ResearchResult)) {
    Write-Host "Research failed or returned empty result." -ForegroundColor Red
    exit 1
}

# 6. Save Output
$ResearchDir = "drafts/research"
if (-not (Test-Path $ResearchDir)) {
    New-Item -ItemType Directory -Path $ResearchDir -Force | Out-Null
}

$OutputPath = "content/posts/$Slug/files/research.md"
$ResearchResult | Set-Content -Path $OutputPath -Encoding UTF8

Write-Host "✓ Research saved to: $OutputPath" -ForegroundColor Green
Write-Host ""
Write-Host "Preview:" -ForegroundColor Gray
$ResearchResult | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
Write-Host "..." -ForegroundColor DarkGray
Write-Host ""
