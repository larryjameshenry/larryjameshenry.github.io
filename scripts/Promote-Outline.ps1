<#
.SYNOPSIS
    Promote an outline from plans/ to content/posts/
.DESCRIPTION
    Moves an outline file from the plans directory to Hugo content directory
    and extracts proper metadata from the outline
.PARAMETER SeriesName
    The series/plan name
.PARAMETER Number
    The article number to promote (e.g., 1 for article 1)
.PARAMETER Pillar
    Promote the pillar article instead of numbered article
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SeriesName,

    [Parameter(Mandatory=$false)]
    [int]$Number = 0,

    [Parameter(Mandatory=$false)]
    [switch]$Pillar
)

$PlanDir = "plans/$SeriesName"
$OutlinesDir = "$PlanDir/outlines"
$ContentDir = "content/posts"

# Determine which outline to promote
if ($Pillar) {
    $OutlineFile = "$OutlinesDir/00-pillar.md"
    $ArticleName = "pillar"
} elseif ($Number -gt 0) {
    $OutlineFile = "$OutlinesDir/{0:D2}-article-{0}.md" -f $Number
    $ArticleName = "article-$Number"
} else {
    Write-Error "Specify either -Number [N] or -Pillar"
    exit 1
}

if (-not (Test-Path $OutlineFile)) {
    Write-Error "Outline not found: $OutlineFile"
    Write-Host ""
    Write-Host "Available outlines:" -ForegroundColor Yellow
    Get-ChildItem $OutlinesDir -Filter "*.md" | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Gray
    }
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Promoting Outline to Content" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Read outline
$OutlineContent = Get-Content $OutlineFile -Raw

# Extract title from front matter or content
$Title = ""
if ($OutlineContent -match '(?ms)^---\s*$.+?^title:\s*["\x27]?([^"\x27\r\n]+)["\x27]?\s*$') {
    $Title = $Matches[1].Trim()
} elseif ($OutlineContent -match '(?m)^#\s+(.+)$') {
    $Title = $Matches[1].Trim()
}

# Generate slug from title or use default
if ($Title) {
    $Slug = $Title.ToLower() -replace '[^\w\s-]', '' -replace '\s+', '-'
    Write-Host "Extracted title: $Title" -ForegroundColor Yellow
} else {
    $Slug = "$SeriesName-$ArticleName"
    Write-Host "No title found, using default slug" -ForegroundColor Yellow
}

$DestFile = "$ContentDir/$Slug.md"

# Check if destination already exists
if (Test-Path $DestFile) {
    Write-Warning "Article already exists: $DestFile"
    $Confirm = Read-Host "Overwrite? (y/n)"
    if ($Confirm -ne 'y') {
        exit 0
    }
}

# Update front matter with proper values
$UpdatedContent = $OutlineContent

# If title is still placeholder, try to extract from content
if ($UpdatedContent -match 'title:\s*"Article \d+"') {
    if ($Title -and $Title -notmatch '^Article \d+$') {
        $UpdatedContent = $UpdatedContent -replace 'title:\s*"Article \d+"', "title: `"$Title`""
    } else {
        # Ask user for title
        Write-Host ""
        $UserTitle = Read-Host "Enter article title (or press Enter to keep default)"
        if ($UserTitle) {
            $Title = $UserTitle
            $Slug = $Title.ToLower() -replace '[^\w\s-]', '' -replace '\s+', '-'
            $DestFile = "$ContentDir/$Slug.md"
            $UpdatedContent = $UpdatedContent -replace 'title:\s*"Article \d+"', "title: `"$Title`""
        }
    }
}

# Ensure draft: true is set
if ($UpdatedContent -notmatch 'draft:\s*true') {
    $UpdatedContent = $UpdatedContent -replace '(---\s*\n)', "`$1draft: true`n"
}

# Copy to content directory
Set-Content -Path $DestFile -Value $UpdatedContent -Encoding UTF8

Write-Host ""
Write-Host "✓ Outline promoted successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Location: $DestFile" -ForegroundColor Yellow
Write-Host "Slug: $Slug" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review and edit: code $DestFile" -ForegroundColor White
Write-Host "  2. Expand to full article: .\scripts\Expand-Article.ps1 -Slug $Slug" -ForegroundColor White
Write-Host "  3. Preview with Hugo: hugo server --buildDrafts" -ForegroundColor White
Write-Host ""
