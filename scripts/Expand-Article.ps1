<#
.SYNOPSIS
    Expand an article outline into a full article
.DESCRIPTION
    Uses Gemini CLI to expand outline into complete article content
    Embeds outline directly in prompt (no --add flag needed)
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

$ArticlePath = "content/posts/$Slug.md"

if (-not (Test-Path $ArticlePath)) {
    Write-Error "Article not found: $ArticlePath"
    Write-Host ""
    Write-Host "Available articles:" -ForegroundColor Yellow
    Get-ChildItem "content/posts" -Filter "*.md" | ForEach-Object {
        Write-Host "  - $($_.BaseName)" -ForegroundColor Gray
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

Write-Host "Expanding article using Gemini CLI..." -ForegroundColor Yellow
Write-Host "This may take 60-120 seconds..." -ForegroundColor Gray
Write-Host ""

try {
    # Build expansion prompt with outline embedded
    $ExpansionPrompt = @"
Expand the following article outline into a complete, well-written, publication-ready article.

WRITING GUIDELINES:
- Avoid AI clichés: "delve", "leverage", "robust", "seamless", "cutting-edge"
- Use specific numbers and metrics instead of vague claims
- Active voice and direct statements
- Concrete examples with working code
- Natural transitions without formulaic phrases
- Technical precision over marketing language

CONTENT REQUIREMENTS:
- Word count: 1500-2500 words
- Include 2-3 complete code examples with comments
- At least 1 detailed step-by-step walkthrough
- Best practices section with do's and don'ts
- Troubleshooting section with 2-3 common issues
- Conclusion with 5 specific, actionable takeaways

STRUCTURE:
- Maintain the outline's section structure
- Expand all placeholder sections
- Use conversational but professional tone
- Break complex concepts into digestible explanations
- Front-load important information

Change draft: true to draft: false when complete.

--- OUTLINE START ---
$CurrentContent
--- OUTLINE END ---

Generate the complete, expanded article with Hugo front matter.
"@

    # Call Gemini with embedded prompt
    $ExpandedContent = & gemini $ExpansionPrompt 2>&1 | Out-String

    if ($LASTEXITCODE -ne 0) {
        throw "Gemini CLI returned exit code $LASTEXITCODE"
    }

    # Clean output (remove debug messages)
    $Lines = $ExpandedContent -split "`r?`n"
    $CleanLines = $Lines | Where-Object {
        $_ -notmatch '^Loaded cached credentials' -and
        $_ -notmatch '^Loading' -and
        $_ -notmatch '^Initializing' -and
        $_ -notmatch '^Using model' -and
        $_ -notmatch '^Gemini CLI' -and
        $_ -notmatch '^Generating content' -and
        $_ -notmatch '^Streaming'
    }

    # Remove leading empty lines
    while ($CleanLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($CleanLines[0])) {
        $CleanLines = $CleanLines[1..($CleanLines.Count - 1)]
    }

    $ExpandedContent = ($CleanLines -join "`n").Trim()

    if ([string]::IsNullOrWhiteSpace($ExpandedContent)) {
        throw "Gemini CLI returned empty content"
    }

    # Write expanded content
    Set-Content -Path $ArticlePath -Value $ExpandedContent -Encoding UTF8 -NoNewline

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
    Write-Host "  3. Fact-check: .\scripts\Test-ArticleAccuracy.ps1 -Slug $Slug" -ForegroundColor White
    Write-Host "  4. Publish: .\scripts\Publish-Article.ps1 -Slug $Slug" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Error "Failed to expand article: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check if outline is properly formatted: code $ArticlePath" -ForegroundColor Gray
    Write-Host "  2. Wait 5-10 minutes for rate limits" -ForegroundColor Gray
    Write-Host "  3. Try manually with: gemini 'Expand this outline: ...' " -ForegroundColor Gray
    Write-Host "  4. Restore backup: Copy-Item $TimestampedBackup $ArticlePath -Force" -ForegroundColor Gray
    exit 1
}
