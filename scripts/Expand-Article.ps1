<#
.SYNOPSIS
    Expand an article outline into a full article
.DESCRIPTION
    Uses Gemini CLI /expand command to expand outline into complete article content
.PARAMETER Slug
    The article slug/filename (without .md extension)
.PARAMETER SkipBackup
    Skip creating backup file before expansion
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup
)

# Logic to determine path: check for bundle first, then standalone file
$BundlePath = "content/posts/$Slug/index.md"
$StandalonePath = "content/posts/$Slug.md"

if (Test-Path $BundlePath) {
    $ArticlePath = $BundlePath
    Write-Host "✓ Found article bundle: $ArticlePath" -ForegroundColor Gray
} elseif (Test-Path $StandalonePath) {
    $ArticlePath = $StandalonePath
    Write-Host "✓ Found standalone article: $ArticlePath" -ForegroundColor Gray
} else {
    Write-Error "Article not found (checked for bundle and standalone file): $Slug"
    Write-Host ""
    Write-Host "Available articles:" -ForegroundColor Yellow

    # List bundles
    Get-ChildItem "content/posts" -Directory | ForEach-Object {
        if (Test-Path "$($_.FullName)/index.md") {
            Write-Host "  - $($_.Name) (bundle)" -ForegroundColor Gray
        }
    }

    # List standalone files
    Get-ChildItem "content/posts" -Filter "*.md" | ForEach-Object {
        Write-Host "  - $($_.BaseName) (file)" -ForegroundColor Gray
    }
    exit 1
}

# Read current content
$CurrentContent = Get-Content $ArticlePath -Raw

# Check if already expanded
$IsDraft = $CurrentContent -match 'draft:\s*true'
$ContentLength = $CurrentContent.Length

if (-not $IsDraft) {
    Write-Warning "Article appears to be already published (draft: false)"
    $Confirm = Read-Host "Continue expansion anyway? (y/n)"
    if ($Confirm -ne 'y') {
        exit 0
    }
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Expanding Article to Full Content" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Article: $Slug" -ForegroundColor Yellow
Write-Host ""

# Create backup unless skipped
if (-not $SkipBackup) {
    $BackupTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $BackupDir = "backups"

    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }

    $TimestampedBackup = "$BackupDir/$Slug-$BackupTimestamp.md"
    Copy-Item $ArticlePath $TimestampedBackup -Force

    Write-Host "✓ Backup created: $TimestampedBackup" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Expanding article using Gemini CLI /expand command..." -ForegroundColor Yellow
Write-Host "This may take 30-60 seconds..." -ForegroundColor Gray
Write-Host ""

try {
    # Use /expand command from TOML - all prompt logic is there
    $ExpandedContent = Get-Content $ArticlePath -Raw | gemini "/expand"

    if ([string]::IsNullOrWhiteSpace($ExpandedContent)) {
        throw "Gemini CLI returned empty content"
    }

    # Clean up formatting issues before writing

    # 0. Remove wrapping markdown code blocks if present
    if ($ExpandedContent -match '(?s)^```markdown\s*(.*)\s*```$') {
        $ExpandedContent = $Matches[1]
    } elseif ($ExpandedContent -match '(?s)^```\s*(.*)\s*```$') {
        $ExpandedContent = $Matches[1]
    }

    # 1. Ensure front matter delimiters have newlines
    $ExpandedContent = $ExpandedContent -replace '(?m)^---\s*([a-z])', "---\n$1"
    $ExpandedContent = $ExpandedContent -replace '(?m)([a-z0-9"\]])\s*---$', "$1\n---"

    # 2. Fix "wall of text" issues where paragraphs are joined (look for period followed immediately by capital letter)
    # This adds a double newline to separate paragraphs that were accidentally merged
    $ExpandedContent = $ExpandedContent -replace '([a-z]\.)([A-Z])', "$1`n`n$2"

    # Write expanded content
    $ExpandedContent | Out-File $ArticlePath -Encoding UTF8

    $WordCount = ($ExpandedContent -split '\s+').Count

    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Article Expanded Successfully!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Word Count: ~$WordCount words" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Review: code $ArticlePath" -ForegroundColor White
    Write-Host "  2. Test: hugo server --buildDrafts" -ForegroundColor White
    Write-Host "  3. Polish: Get-Content $ArticlePath -Raw | gemini '/finalize' > review.md" -ForegroundColor White
    Write-Host "  4. Fact-check: .\scripts\Test-ArticleAccuracy.ps1 -Slug $Slug" -ForegroundColor White
    Write-Host "  5. Publish: .\scripts\Publish-Article.ps1 -Slug $Slug" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Error "Failed to expand article: $_"
    exit 1
}
