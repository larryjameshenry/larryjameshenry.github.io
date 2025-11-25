<#
.SYNOPSIS
    Promote an outline from plans/ to content/posts/ as a Hugo page bundle
.DESCRIPTION
    Creates a page bundle directory structure with index.md for the article
    and space for bundled resources (images, files, etc.)
.PARAMETER SeriesName
    The series/plan name
.PARAMETER Number
    The article number to promote (e.g., 1 for article 1)
.PARAMETER Pillar
    Promote the pillar article instead of numbered article
.PARAMETER Slug
    Optional: Override auto-generated slug
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SeriesName,

    [Parameter(Mandatory=$false)]
    [int]$Number = 0,

    [Parameter(Mandatory=$false)]
    [switch]$Pillar,

    [Parameter(Mandatory=$false)]
    [string]$Slug
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
Write-Host "  Promoting Outline to Hugo Page Bundle" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Read outline
$OutlineContent = Get-Content $OutlineFile -Raw

# Extract title from front matter or content (simplified approach)
$Title = ""
if ($OutlineContent -match 'title:\s*(.+)') {
    $Title = $Matches[1].Trim() -replace '^["' + "']|[" + '"]$', ''
}

# Fallback: look for first H1 heading
if (-not $Title -or $Title -match '^Article \d+') {
    if ($OutlineContent -match '(?m)^#\s+(.+)$') {
        $Title = $Matches[1].Trim()
    }
}

# Generate slug from title or use override
if ($Slug) {
    # Use provided slug
    Write-Host "Using provided slug: $Slug" -ForegroundColor Yellow
} elseif ($Title -and $Title -notmatch '^Article \d+') {
    $Slug = $Title.ToLower() -replace '[^\w\s-]', '' -replace '\s+', '-'
    Write-Host "Extracted title: $Title" -ForegroundColor Yellow
    Write-Host "Generated slug: $Slug" -ForegroundColor Yellow
} else {
    # Ask user for title
    Write-Host ""
    Write-Host "No clear title found in outline." -ForegroundColor Yellow
    $UserTitle = Read-Host "Enter article title"

    if ([string]::IsNullOrWhiteSpace($UserTitle)) {
        # Use default slug
        $Slug = "$SeriesName-$ArticleName"
        Write-Host "Using default slug: $Slug" -ForegroundColor Yellow
    } else {
        $Title = $UserTitle
        $Slug = $Title.ToLower() -replace '[^\w\s-]', '' -replace '\s+', '-'
        Write-Host "Generated slug: $Slug" -ForegroundColor Yellow
    }
}

# Create bundle directory
$BundleDir = "$ContentDir/$Slug"
$IndexFile = "$BundleDir/index.md"

# Check if bundle already exists
if (Test-Path $BundleDir) {
    Write-Warning "Page bundle already exists: $BundleDir"
    $Confirm = Read-Host "Overwrite? (y/n)"
    if ($Confirm -ne 'y') {
        exit 0
    }
} else {
    # Create bundle directory
    New-Item -ItemType Directory -Path $BundleDir -Force | Out-Null
    Write-Host "✓ Created bundle directory: $BundleDir" -ForegroundColor Green
}

# Update content
$UpdatedContent = $OutlineContent

# Update title if we have a better one
if ($Title -and $Title -notmatch '^Article \d+$') {
    if ($UpdatedContent -match 'title:\s*"Article \d+"') {
        $UpdatedContent = $UpdatedContent -replace 'title:\s*"Article \d+"', "title: `"$Title`""
    }
}

# Ensure draft: true is set
if ($UpdatedContent -notmatch 'draft:\s*true') {
    $UpdatedContent = $UpdatedContent -replace '(^---\s*[\r\n]+)', "`$1draft: true`n"
}

# Add bundle-specific front matter if not present
if ($UpdatedContent -notmatch 'slug:') {
    # Add slug to front matter
    $UpdatedContent = $UpdatedContent -replace '(^---\s*[\r\n]+)', "`$1slug: `"$Slug`"`n"
}

# Write index.md
Set-Content -Path $IndexFile -Value $UpdatedContent -Encoding UTF8

Write-Host "✓ Created index.md in bundle" -ForegroundColor Green

# Create placeholder directories for common bundle resources
$ResourceDirs = @('images', 'files')
foreach ($Dir in $ResourceDirs) {
    $ResourcePath = "$BundleDir/$Dir"
    if (-not (Test-Path $ResourcePath)) {
        New-Item -ItemType Directory -Path $ResourcePath -Force | Out-Null
    }
}

Write-Host "✓ Created resource directories (images, files)" -ForegroundColor Green

# Create a README in the bundle to explain structure
$ReadmeContent = @"
# Page Bundle: $Title

This is a Hugo page bundle for the article: **$Title**

## Structure

- ``index.md`` - Main article content
- ``images/`` - Article-specific images (referenced as ``images/filename.png``)
- ``files/`` - Downloadable files, scripts, or other resources

## Usage

### Adding Images

1. Place images in the ``images/`` directory
2. Reference in markdown: ``![Alt text](images/your-image.png)``

### Adding Files

1. Place files in the ``files/`` directory
2. Link in markdown: ``[Download](files/your-file.zip)``

### Bundle Benefits

- All resources are self-contained
- Images and files move with the article
- Simpler relative paths
- Better organization

## Next Steps

1. Review: ``code $IndexFile``
2. Add images to: ``$BundleDir/images/``
3. Add files to: ``$BundleDir/files/``
4. Expand article: ``.\scripts\Expand-Article.ps1 -Slug $Slug``
5. Preview: ``hugo server --buildDrafts``
"@

Set-Content -Path "$BundleDir/README.md" -Value $ReadmeContent -Encoding UTF8
Write-Host "✓ Created README.md with bundle documentation" -ForegroundColor Green

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Page Bundle Created Successfully!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Bundle Location: $BundleDir" -ForegroundColor Yellow
Write-Host "Article: $IndexFile" -ForegroundColor Yellow
Write-Host "Slug: $Slug" -ForegroundColor Yellow
Write-Host ""
Write-Host "Bundle Structure:" -ForegroundColor Cyan
Write-Host "  $Slug/" -ForegroundColor White
Write-Host "  ├── index.md          # Main article content" -ForegroundColor Gray
Write-Host "  ├── README.md         # Bundle documentation" -ForegroundColor Gray
Write-Host "  ├── images/           # Article images" -ForegroundColor Gray
Write-Host "  └── files/            # Downloadable resources" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review article:      code $IndexFile" -ForegroundColor White
Write-Host "  2. Add images to:       $BundleDir/images/" -ForegroundColor White
Write-Host "  3. Add files to:        $BundleDir/files/" -ForegroundColor White
Write-Host "  4. Expand article:      .\scripts\Expand-Article.ps1 -Slug $Slug" -ForegroundColor White
Write-Host "  5. Preview with Hugo:   hugo server --buildDrafts" -ForegroundColor White
Write-Host ""
Write-Host "Tips:" -ForegroundColor Yellow
Write-Host "  - Reference images: ![Alt](images/filename.png)" -ForegroundColor Gray
Write-Host "  - Link files: [Download](files/filename.zip)" -ForegroundColor Gray
Write-Host "  - All resources stay with the article" -ForegroundColor Gray
Write-Host ""
