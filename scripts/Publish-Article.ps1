<#
.SYNOPSIS
    Publish an article by changing draft status and committing to git
.DESCRIPTION
    Changes draft: true to draft: false, updates the date to current timestamp,
    commits the article to git, and pushes to trigger GitHub Pages deployment.
    Optionally runs a pre-publish check and preview.
.PARAMETER Slug
    The article slug/filename (without .md extension)
.PARAMETER CommitMessage
    Optional custom commit message (default: "Publish article: {slug}")
.PARAMETER SkipPreview
    Skip the local preview step before publishing
.PARAMETER SkipCheck
    Skip pre-publish validation checks
.PARAMETER Force
    Force publish even if article appears to be draft quality
.EXAMPLE
    .\scripts\Publish-Article.ps1 -Slug "powershell-automation-basics"
.EXAMPLE
    .\scripts\Publish-Article.ps1 -Slug "azure-pipelines" -CommitMessage "Initial Azure DevOps series article"
.EXAMPLE
    .\scripts\Publish-Article.ps1 -Slug "sql-performance" -SkipPreview -Force
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$false)]
    [string]$CommitMessage,

    [Parameter(Mandatory=$false)]
    [switch]$SkipPreview,

    [Parameter(Mandatory=$false)]
    [switch]$SkipCheck,

    [Parameter(Mandatory=$false)]
    [switch]$Force
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

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Publishing Article" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Article: $Slug" -ForegroundColor Yellow
Write-Host "Path: $ArticlePath" -ForegroundColor Gray
Write-Host ""

# Read article content
$Content = Get-Content $ArticlePath -Raw

# Check if already published
$IsDraft = $Content -match 'draft:\s*true'

if (-not $IsDraft) {
    Write-Warning "Article is already published (draft: false)"
    Write-Host ""
    $Confirm = Read-Host "Re-publish anyway? This will update the date. (y/n)"
    if ($Confirm -ne 'y') {
        Write-Host "Publish cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Pre-publish validation checks
if (-not $SkipCheck) {
    Write-Host "Running pre-publish checks..." -ForegroundColor Yellow
    Write-Host ""

    $Issues = @()
    $Warnings = @()

    # Check 1: Minimum content length
    $WordCount = ($Content -split '\s+').Count
    if ($WordCount -lt 500) {
        $Issues += "Article is too short ($WordCount words, minimum 500 recommended)"
    } elseif ($WordCount -lt 800) {
        $Warnings += "Article is short ($WordCount words, 800-2000 recommended)"
    }

    # Check 2: Has code examples (for technical content)
    if ($Content -notmatch '```
        $Warnings += "No code blocks found (consider adding examples)"
    }

    # Check 3: Has proper front matter
    if ($Content -notmatch '^---\s*$.*?^---\s*$') {
        $Issues += "Invalid or missing front matter"
    }

    # Check 4: Has title
    if ($Content -notmatch 'title:\s*["\']?.+["\']?') {
        $Issues += "Missing title in front matter"
    }

    # Check 5: Has description
    if ($Content -notmatch 'description:\s*["\']?.+["\']?') {
        $Issues += "Missing description in front matter"
    }

    # Check 6: Has tags
    if ($Content -notmatch 'tags:\s*$$.+$$') {
        $Warnings += "No tags defined (recommended for SEO)"
    }

    # Check 7: Check for common placeholders
    $PlaceholderPatterns = @(
        '$$PLACEHOLDER',
        '$$TODO$$',
        '$$TK$$',
        'TODO:',
        'FIXME:'
    )

    foreach ($Pattern in $PlaceholderPatterns) {
        if ($Content -match $Pattern) {
            $Issues += "Contains placeholder text: $Pattern"
        }
    }

    # Check 8: Has headings
    $HeadingCount = ([regex]::Matches($Content, '^#{2,3}\s+.+$', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    if ($HeadingCount -lt 3) {
        $Warnings += "Few section headings ($HeadingCount found, 3+ recommended)"
    }

    # Display results
    if ($Issues.Count -gt 0) {
        Write-Host "✗ Issues Found:" -ForegroundColor Red
        foreach ($Issue in $Issues) {
            Write-Host "  - $Issue" -ForegroundColor Red
        }
        Write-Host ""

        if (-not $Force) {
            Write-Host "Fix these issues before publishing, or use -Force to publish anyway." -ForegroundColor Yellow
            exit 1
        } else {
            Write-Host "Continuing due to -Force flag..." -ForegroundColor Yellow
            Write-Host ""
        }
    }

    if ($Warnings.Count -gt 0) {
        Write-Host "⚠ Warnings:" -ForegroundColor Yellow
        foreach ($Warning in $Warnings) {
            Write-Host "  - $Warning" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    if ($Issues.Count -eq 0 -and $Warnings.Count -eq 0) {
        Write-Host "✓ All checks passed" -ForegroundColor Green
        Write-Host ""
    }
}

# Optional: Run fact-check
if (-not $SkipCheck) {
    Write-Host "Fact-checking article..." -ForegroundColor Yellow
    $FactCheckChoice = Read-Host "Run fact-check before publishing? (y/n/skip)"

    if ($FactCheckChoice -eq 'y') {
        $TempReport = "temp-factcheck-$Slug.md"

        & "$PSScriptRoot\Test-ArticleAccuracy.ps1" -Slug $Slug -OutputFile $TempReport

        if (Test-Path $TempReport) {
            $FactCheckContent = Get-Content $TempReport -Raw

            if ($FactCheckContent -match 'Severity:\s*(FAIL|MAJOR ISSUES)') {
                Write-Host ""
                Write-Error "Article has critical accuracy issues. Publishing blocked."
                Write-Host "Review: $TempReport" -ForegroundColor Yellow
                exit 1
            }

            Remove-Item $TempReport -Force -ErrorAction SilentlyContinue
        }
    }
}


# Preview before publishing
if (-not $SkipPreview) {
    Write-Host "Opening local preview..." -ForegroundColor Yellow
    Write-Host "Review the article at: http://localhost:1313" -ForegroundColor Cyan
    Write-Host ""

    # Start Hugo server in background
    $HugoProcess = Start-Process "hugo" -ArgumentList "server --buildDrafts --navigateToChanged" -PassThru -NoNewWindow

    Start-Sleep -Seconds 3

    Write-Host "Hugo server started (PID: $($HugoProcess.Id))" -ForegroundColor Gray
    Write-Host ""

    $Confirm = Read-Host "Ready to publish? (y/n)"

    # Stop Hugo server
    Stop-Process -Id $HugoProcess.Id -Force -ErrorAction SilentlyContinue

    if ($Confirm -ne 'y') {
        Write-Host "Publish cancelled." -ForegroundColor Yellow
        exit 0
    }

    Write-Host ""
}

Write-Host "Preparing article for publication..." -ForegroundColor Yellow

# Change draft status
$Content = $Content -replace 'draft:\s*true', 'draft: false'

# Update date to current timestamp
$Now = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
$Content = $Content -replace 'date:\s*[\d\-T:+Z]+', "date: $Now"

# Write updated content
$Content | Out-File $ArticlePath -Encoding UTF8 -NoNewline

Write-Host "✓ Draft status changed to: published" -ForegroundColor Green
Write-Host "✓ Date updated to: $Now" -ForegroundColor Green
Write-Host ""

# Git operations
Write-Host "Committing to git..." -ForegroundColor Yellow

# Check git status
$GitStatus = git status --porcelain $ArticlePath 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Error "Git error: $GitStatus"
    exit 1
}

# Stage the article
git add $ArticlePath

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to stage article"
    exit 1
}

# Create commit message
if (-not $CommitMessage) {
    # Extract title for better commit message
    if ($Content -match 'title:\s*["\']?([^"\'\r\n]+)["\']?') {
        $Title = $Matches.Trim()
        $CommitMessage = "Publish article: $Title"
    } else {
        $CommitMessage = "Publish article: $Slug"
    }
}

# Commit
git commit -m $CommitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to commit article"
    exit 1
}

Write-Host "✓ Changes committed" -ForegroundColor Green
Write-Host ""

# Push to remote
Write-Host "Pushing to GitHub..." -ForegroundColor Yellow

$CurrentBranch = git branch --show-current
git push origin $CurrentBranch

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push to GitHub"
    Write-Host ""
    Write-Host "Changes are committed locally but not pushed." -ForegroundColor Yellow
    Write-Host "Push manually with: git push origin $CurrentBranch" -ForegroundColor Gray
    exit 1
}

Write-Host "✓ Pushed to GitHub" -ForegroundColor Green
Write-Host ""

# Get repository info for links
$RemoteUrl = git config --get remote.origin.url
$RepoPath = ""

if ($RemoteUrl -match 'github\.com[:/](.+?)(?:\.git)?$') {
    $RepoPath = $Matches
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Article Published Successfully! 🎉" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status:" -ForegroundColor Yellow
Write-Host "  ✓ Draft status: published" -ForegroundColor Green
Write-Host "  ✓ Committed to git" -ForegroundColor Green
Write-Host "  ✓ Pushed to GitHub" -ForegroundColor Green
Write-Host "  ⏳ GitHub Actions deploying..." -ForegroundColor Yellow
Write-Host ""

if ($RepoPath) {
    Write-Host "Monitor deployment:" -ForegroundColor Cyan
    Write-Host "  Workflow: https://github.com/$RepoPath/actions" -ForegroundColor Gray
    Write-Host "  Live site: https://$($RepoPath -replace '^([^/]+)/.*', '$1').github.io" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Deployment typically takes 1-3 minutes." -ForegroundColor Gray
Write-Host ""
Write-Host "What's Next:" -ForegroundColor Cyan
Write-Host "  - Monitor GitHub Actions for deployment status" -ForegroundColor White
Write-Host "  - Share article on social media" -ForegroundColor White
Write-Host "  - Update any related documentation" -ForegroundColor White

if ($Content -match-match 'series:\s*$$"?([^"$$]+)"?$$') {
    $SeriesName = $Matches[1]
    Write-Host "  - Consider publishing next article in '$SeriesName' series" -ForegroundColor White
}

Write-Host ""
