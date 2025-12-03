<#
.SYNOPSIS
    Generate featured image prompts for an article
.DESCRIPTION
    Uses Gemini to analyze an article and generate high-quality prompts for
    text-to-image tools (Midjourney, DALL-E, Imagen).
.PARAMETER Slug
    The article slug
.PARAMETER Model
    Gemini model to use (default: gemini-3-pro-preview)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

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

# 1. Find Article
$BundlePath = "content/posts/$Slug/index.md"
$SingleFilePath = "content/posts/$Slug.md"

if (Test-Path $BundlePath) {
    $ArticlePath = $BundlePath
    $OutputDir = "content/posts/$Slug/files/"
} elseif (Test-Path $SingleFilePath) {
    $ArticlePath = $SingleFilePath
    $OutputDir = "drafts/research/" # Fallback
} else {
    Write-Error "Article not found: $Slug"
    exit 1
}

# 2. Create Output Directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Generating Image Prompts" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Article: $Slug" -ForegroundColor Yellow
Write-Host ""

# 3. Read Command Template
$CommandPath = ".gemini/commands/image-prompt.toml"
if (-not (Test-Path $CommandPath)) {
    Write-Error "Command template not found: $CommandPath"
    exit 1
}

$CommandContent = Get-Content $CommandPath -Raw
if ($CommandContent -match '(?s)prompt\s*=\s*"""(.*?)"""') {
    $PromptTemplate = $Matches[1]
} else {
    Write-Error "Could not parse prompt from TOML"
    exit 1
}

# 4. Read Article
$ArticleContent = Get-Content $ArticlePath -Raw

# 5. Generate
$FullPrompt = $PromptTemplate -replace '\{\{args\}\}', $ArticleContent

Write-Host "Analyzing article and dreaming up visuals..." -ForegroundColor Yellow

try {
    $Result = & gemini --yolo --model $Model $FullPrompt 2>&1 | Out-String
    
    if ($LASTEXITCODE -ne 0) {
        throw "Gemini CLI failed"
    }

    $CleanedResult = Clean-GeminiOutput -RawOutput $Result

    # 6. Save Output
    $OutputFile = Join-Path $OutputDir "image-prompts.md"
    Set-Content -Path $OutputFile -Value $CleanedResult -Encoding UTF8

    Write-Host "✓ Prompts saved to: $OutputFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "Preview of Concept 1:" -ForegroundColor Cyan
    $CleanedResult -split "`n" | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host ""
    Write-Host "Next Step: Open $OutputFile and copy a prompt to your image generator." -ForegroundColor White
    Write-Host ""

} catch {
    Write-Error "Failed to generate prompts: $_"
    exit 1
}
