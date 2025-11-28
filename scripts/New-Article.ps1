<#
.SYNOPSIS
    Create a new article with AI-generated outline
.DESCRIPTION
    Uses Gemini CLI commands to research a topic and generate an article outline.
    Can optionally be part of a series.
.PARAMETER Topic
    The article topic/title
.PARAMETER Slug
    Optional URL slug
.PARAMETER Series
    Optional series name for topic clusters
.PARAMETER Tags
    Optional comma-separated tags
.PARAMETER Category
    Optional category
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Topic,

    [Parameter(Mandatory=$false)]
    [string]$Slug,

    [Parameter(Mandatory=$false)]
    [string]$Series,

    [Parameter(Mandatory=$false)]
    [string]$Tags,

    [Parameter(Mandatory=$false)]
    [string]$Category = "Technical"
)

# Generate slug from topic if not provided
if (-not $Slug) {
    $Slug = $Topic.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-'
}

# Use Bundle format by default
$ArticleDir = "content/posts/$Slug"
$ArticlePath = "$ArticleDir/index.md"

if (Test-Path $ArticleDir) {
    Write-Error "Article bundle already exists at: $ArticleDir"
    exit 1
}
if (Test-Path "content/posts/$Slug.md") {
    Write-Error "Legacy article file already exists at: content/posts/$Slug.md"
    exit 1
}

# Create bundle directory
New-Item -ItemType Directory -Path $ArticleDir -Force | Out-Null

Write-Host "Creating new article bundle: $Topic" -ForegroundColor Cyan

# Research phase using /research command
Write-Host "Step 1: Researching topic..." -ForegroundColor Yellow
$ResearchFile = "temp-research-$Slug.md"
New-Item -ItemType File -Path $ResearchFile -Force | Out-Null
Write-Output "# Research for: $Topic" | Out-File $ResearchFile -Encoding UTF8
gemini "/research $Topic" | Out-File $ResearchFile -Append -Encoding UTF8

# Build outline arguments
Write-Host "Step 2: Generating outline..." -ForegroundColor Yellow
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

$OutlineArgs = "Topic: $Topic`nDate: $CurrentDate`nCategory: $Category"
if ($Series) { $OutlineArgs += "`nSeries: $Series" }
if ($Tags) { $OutlineArgs += "`nTags: $Tags" }

# Use /outline command from TOML
Get-Content $ResearchFile -Raw | gemini "/outline $OutlineArgs" | Out-File $ArticlePath -Encoding UTF8
Remove-Item $ResearchFile -Force

Write-Host "✓ Article outline created: $ArticlePath" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review: code $ArticlePath"
Write-Host "  2. Expand: .\scripts\Expand-Article.ps1 -Slug $Slug"
