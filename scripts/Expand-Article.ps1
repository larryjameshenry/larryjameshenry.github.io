<#
.SYNOPSIS
    Expand an article outline into a full article
.DESCRIPTION
    Uses Gemini CLI to expand outline into complete article content with
    proper code examples, detailed explanations, and publication-ready prose.
.PARAMETER Slug
    The article slug/filename (without .md extension)
.PARAMETER SkipBackup
    Skip creating backup file before expansion
.EXAMPLE
    .\scripts\Expand-Article.ps1 -Slug "powershell-automation-basics"
.EXAMPLE
    .\scripts\Expand-Article.ps1 -Slug "azure-devops-pipelines" -SkipBackup
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup
)

$ArticlePath = "content/posts/$Slug.md"

# Validate article exists
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

# Check if already expanded (look for draft: false or significant length)
$IsDraft = $CurrentContent -match 'draft:\s*true'
$ContentLength = $CurrentContent.Length

if (-not $IsDraft) {
    Write-Warning "Article appears to be already published (draft: false)"
    $Confirm = Read-Host "Continue expansion anyway? This will overwrite existing content. (y/n)"
    if ($Confirm -ne 'y') {
        Write-Host "Expansion cancelled." -ForegroundColor Yellow
        exit 0
    }
}

if ($ContentLength -gt 5000) {
    Write-Warning "Article is already substantial ($ContentLength characters)"
    $Confirm = Read-Host "This looks like it might already be expanded. Continue? (y/n)"
    if ($Confirm -ne 'y') {
        Write-Host "Expansion cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Expanding Article to Full Content" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Article: $Slug" -ForegroundColor Yellow
Write-Host "Path: $ArticlePath" -ForegroundColor Gray
Write-Host ""

# Create backup unless skipped
if (-not $SkipBackup) {
    $BackupPath = "$ArticlePath.backup"
    $BackupTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $BackupDir = "backups"

    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }

    $TimestampedBackup = "$BackupDir/$Slug-$BackupTimestamp.md"

    Copy-Item $ArticlePath $BackupPath -Force
    Copy-Item $ArticlePath $TimestampedBackup -Force

    Write-Host "✓ Backup created: $BackupPath" -ForegroundColor Green
    Write-Host "✓ Timestamped backup: $TimestampedBackup" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Expanding article using Gemini CLI..." -ForegroundColor Yellow
Write-Host "This may take 30-60 seconds depending on article complexity..." -ForegroundColor Gray
Write-Host ""

try {
    # Expand article using Gemini CLI with the outline as context
    $ExpandedContent = gemini --add $ArticlePath "/expand"

    if ([string]::IsNullOrWhiteSpace($ExpandedContent)) {
        throw "Gemini CLI returned empty content"
    }

    # Check if expansion actually happened (look for substantial increase)
    if ($ExpandedContent.Length -le $CurrentContent.Length * 1.2) {
        Write-Warning "Expansion may not have worked properly (content length similar)"
        Write-Host "Original: $($CurrentContent.Length) chars" -ForegroundColor Gray
        Write-Host "Expanded: $($ExpandedContent.Length) chars" -ForegroundColor Gray
        Write-Host ""

        $Confirm = Read-Host "Continue saving anyway? (y/n)"
        if ($Confirm -ne 'y') {
            Write-Host "Expansion cancelled. Original file unchanged." -ForegroundColor Yellow
            if (-not $SkipBackup) {
                Remove-Item $BackupPath -Force -ErrorAction SilentlyContinue
            }
            exit 0
        }
    }

    # Write expanded content back to file
    $ExpandedContent | Out-File $ArticlePath -Encoding UTF8 -NoNewline

    # Remove temporary backup if successful (keep timestamped one)
    if (-not $SkipBackup) {
        Remove-Item $BackupPath -Force -ErrorAction SilentlyContinue
    }

    $FinalLength = $ExpandedContent.Length
    $WordCount = ($ExpandedContent -split '\s+').Count

    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Article Expanded Successfully!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Statistics:" -ForegroundColor Yellow
    Write-Host "  Characters: $FinalLength" -ForegroundColor Gray
    Write-Host "  Words: ~$WordCount" -ForegroundColor Gray
    Write-Host "  File: $ArticlePath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Review the full article:" -ForegroundColor White
    Write-Host "     code $ArticlePath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Test locally with drafts:" -ForegroundColor White
    Write-Host "     hugo server --buildDrafts --navigateToChanged" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Optional - Get AI polish and suggestions:" -ForegroundColor White
    Write-Host "     gemini --add $ArticlePath '/finalize' > review-$Slug.md" -ForegroundColor Gray
    Write-Host "     code review-$Slug.md" -ForegroundColor Gray
    Write-Host ""
  
    Write-Host "  4. When ready to publish:" -ForegroundColor White
    Write-Host "     .\scripts\Publish-Article.ps1 -Slug $Slug" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  RECOMMENDED: Run fact-check before publishing:" -ForegroundColor Yellow
    Write-Host "     .\scripts\Test-ArticleAccuracy.ps1 -Slug $Slug" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  5. When ready to publish:" -ForegroundColor White
    Write-Host "     .\scripts\Publish-Article.ps1 -Slug $Slug" -ForegroundColor Gray
    Write-Host ""

    if (-not $SkipBackup) {
        Write-Host "Backup available at: $TimestampedBackup" -ForegroundColor DarkGray
        Write-Host ""
    }

} catch {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  Expansion Failed!" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Error "Failed to expand article: $_"
    Write-Host ""

    if (-not $SkipBackup -and (Test-Path $BackupPath)) {
        Write-Host "Restoring from backup..." -ForegroundColor Yellow
        Copy-Item $BackupPath $ArticlePath -Force
        Remove-Item $BackupPath -Force
        Write-Host "✓ Original file restored" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  - Check Gemini CLI is configured: gemini config" -ForegroundColor Gray
    Write-Host "  - Verify API key is set: gemini auth" -ForegroundColor Gray
    Write-Host "  - Check outline format is valid" -ForegroundColor Gray
    Write-Host "  - Try expanding manually: gemini --add $ArticlePath '/expand'" -ForegroundColor Gray
    Write-Host ""

    exit 1
}
