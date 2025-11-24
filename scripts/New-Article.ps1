<#
.SYNOPSIS
    Create a new article with AI-generated outline
.DESCRIPTION
    Uses Gemini CLI to research a topic and generate an article outline.
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

$ArticlePath = "content/posts/$Slug.md"

if (Test-Path $ArticlePath) {
    Write-Error "Article already exists at: $ArticlePath"
    exit 1
}

Write-Host "Creating new article: $Topic" -ForegroundColor Cyan

# Research phase
Write-Host "Step 1: Researching topic..." -ForegroundColor Yellow
$ResearchFile = "temp-research-$Slug.md"
New-Item -ItemType File -Path $ResearchFile -Force | Out-Null
Write-Output "# Research for: $Topic" | Out-File $ResearchFile -Encoding UTF8
gemini "/research $Topic" | Out-File $ResearchFile -Append -Encoding UTF8

# Build outline prompt with series/tags if provided
Write-Host "Step 2: Generating outline..." -ForegroundColor Yellow
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

$SeriesLine = if ($Series) { "series: [`"$Series`"]" } else { "" }
$TagsLine = if ($Tags) {
    $TagArray = $Tags -split ',' | ForEach-Object { "`"$($_.Trim())`"" }
    "tags: [$($TagArray -join ', ')]"
} else {
    "tags: []"
}

$OutlinePrompt = @"
Topic: $Topic
Date: $CurrentDate
Category: $Category
$SeriesLine
$TagsLine

Use the research context to create a comprehensive article outline.
Include front matter with the series and tags provided above.
"@

gemini --add $ResearchFile "/outline $OutlinePrompt" | Out-File $ArticlePath -Encoding UTF8
Remove-Item $ResearchFile -Force

Write-Host "✓ Article outline created: $ArticlePath" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review: code $ArticlePath"
Write-Host "  2. Expand: .\scripts\Expand-Article.ps1 -Slug $Slug"
