<#
.SYNOPSIS
    Promote an outline from plans/ to content/posts/ for further work
.DESCRIPTION
    Moves an article outline to the Hugo content directory where it can be
    researched more deeply and expanded into a full article
.PARAMETER SeriesName
    The series/plan name
.PARAMETER Number
    The outline number to promote (e.g., 1, 2, 3)
.PARAMETER Slug
    Optional custom slug (auto-generated from outline title if not provided)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SeriesName,

    [Parameter(Mandatory=$true)]
    [int]$Number,

    [Parameter(Mandatory=$false)]
    [string]$Slug
)

if ($Number -eq 0) {
    # Special case for pillar article
    $OutlineFile = "plans/$SeriesName/outlines/00-pillar.md"
} else {
    # Standard format for supporting articles
    $OutlineFile = "plans/$SeriesName/outlines/{0:D2}-article-{0}.md" -f $Number
}

if (-not (Test-Path $OutlineFile)) {
    Write-Error "Outline file not found: $OutlineFile"
    exit 1
}

Write-Host "Promoting outline to content..." -ForegroundColor Cyan

# Read outline to extract title for slug
$OutlineContent = Get-Content $OutlineFile -Raw

# Remove wrapping markdown code blocks if present
if ($OutlineContent -match '(?s)^```markdown\s*(.*)\s*```$') {
    $OutlineContent = $Matches[1]
} elseif ($OutlineContent -match '(?s)^```\s*(.*)\s*```$') {
    $OutlineContent = $Matches[1]
}

# Extract title from front matter
# Using a simpler regex that is more robust in PowerShell
if ($OutlineContent -match 'title:\s*["'']?([^"''\r\n]+)["'']?') {
    $Title = $Matches[1].Trim()
} else {
    Write-Error "Could not extract title from outline front matter"
    exit 1
}

# Generate slug if not provided
if (-not $Slug) {
    $Slug = $Title.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-'
}

$DestDir = "content/posts/$Slug"
$DestFile = "$DestDir/index.md" # The actual markdown file inside the bundle

# Check if directory already exists
if (Test-Path $DestDir) {
    Write-Error "Article bundle directory already exists at: $DestDir"
    exit 1
}

# Create the directory bundle
New-Item -ItemType Directory -Path $DestDir -Force | Out-Null

# Update the outline with proper date and additional research context
$UpdatedContent = $OutlineContent -replace 'date:\s*[\d\-T:+Z]+', "date: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')"

# Add comment about promotion
# Ensure proper line breaks for front matter
$UpdatedContent = $UpdatedContent -replace '(---\s*\r?\n)', "`$1`n<!-- Promoted from plan: $SeriesName, outline #$Number -->`n<!-- Ready for deep research and expansion -->`n`n"


# Copy to content directory (index.md inside the bundle)
$UpdatedContent | Out-File $DestFile -Encoding UTF8

Write-Host "✓ Outline promoted: $DestDir" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Deep research on this specific topic:" -ForegroundColor White
Write-Host "     Get-Content $DestFile -Raw | gemini '/research [specific aspect]'" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Test draft locally:" -ForegroundColor White
Write-Host "     hugo server --buildDrafts" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. When ready, expand to full article:" -ForegroundColor White
Write-Host "     .\scripts\Expand-Article.ps1 -Slug $Slug" -ForegroundColor Gray
Write-Host ""
