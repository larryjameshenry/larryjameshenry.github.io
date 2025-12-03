<#
.SYNOPSIS
    Display status of all articles in the repository
.DESCRIPTION
    Shows draft status, word count, and publication date for all articles
.PARAMETER ShowDraftsOnly
    Show only draft articles
.PARAMETER ShowPublishedOnly
    Show only published articles
.PARAMETER SortBy
    Sort by: Title, Date, WordCount, Status
.EXAMPLE
    .\scripts\Get-ArticleStatus.ps1
.EXAMPLE
    .\scripts\Get-ArticleStatus.ps1 -ShowDraftsOnly
.EXAMPLE
    .\scripts\Get-ArticleStatus.ps1 -SortBy WordCount
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowDraftsOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowPublishedOnly,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('Title', 'Date', 'WordCount', 'Status')]
    [string]$SortBy = 'Date'
)

$Articles = Get-ChildItem "content/posts" -Filter "*.md" -ErrorAction SilentlyContinue

if (-not $Articles) {
    Write-Host "No articles found in content/posts/" -ForegroundColor Yellow
    exit 0
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Article Status Report" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$ArticleData = @()

foreach ($Article in $Articles) {
    $Content = Get-Content $Article.FullName -Raw
    
    # Extract metadata
    $Title = if ($Content -match 'title:\s*["\']?([^"\'\r\n]+)["\']?') { $Matches } else { $Article.BaseName }[1]
    $Date = if ($Content -match 'date:\s*([\d\-T:+Z]+)') { $Matches } else { "Unknown" }[1]
    $IsDraft = $Content -match 'draft:\s*true'
    $WordCount = ($Content -split '\s+').Count
    $Series = if ($Content -match 'series:\s*$$"?([^"$$]+)"?$$') { $Matches[1] } else { "" }
    
    $Status = if ($IsDraft) { "Draft" } else { "Published" }
    $StatusColor = if ($IsDraft) { "Yellow" } else { "Green" }
    
    # Apply filters
    if ($ShowDraftsOnly -and -not $IsDraft) { continue }
    if ($ShowPublishedOnly -and $IsDraft) { continue }
    
    $ArticleData += [PSCustomObject]@{
        Title = $Title
        Slug = $Article.BaseName
        Status = $Status
        StatusColor = $StatusColor
        Date = $Date
        WordCount = $WordCount
        Series = $Series
    }
}

# Sort
switch ($SortBy) {
    'Title' { $ArticleData = $ArticleData | Sort-Object Title }
    'Date' { $ArticleData = $ArticleData | Sort-Object Date -Descending }
    'WordCount' { $ArticleData = $ArticleData | Sort-Object WordCount -Descending }
    'Status' { $ArticleData = $ArticleData | Sort-Object Status, Date -Descending }
}

# Display
foreach ($Article in $ArticleData) {
    Write-Host $Article.Title -ForegroundColor Cyan
    Write-Host "  Slug: $($Article.Slug)" -ForegroundColor Gray
    Write-Host "  Status: " -NoNewline -ForegroundColor Gray
    Write-Host $Article.Status -ForegroundColor $Article.StatusColor
    Write-Host "  Date: $($Article.Date)" -ForegroundColor Gray
    Write-Host "  Words: $($Article.WordCount)" -ForegroundColor Gray
    if ($Article.Series) {
        Write-Host "  Series: $($Article.Series)" -ForegroundColor Gray
    }
    Write-Host ""
}

# Summary
$DraftCount = ($ArticleData | Where-Object { $_.Status -eq "Draft" }).Count
$PublishedCount = ($ArticleData | Where-Object { $_.Status -eq "Published" }).Count
$TotalWords = ($ArticleData | Measure-Object -Property WordCount -Sum).Sum

Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Total Articles: $($ArticleData.Count)" -ForegroundColor White
Write-Host "  Drafts: $DraftCount" -ForegroundColor Yellow
Write-Host "  Published: $PublishedCount" -ForegroundColor Green
Write-Host "  Total Words: $TotalWords" -ForegroundColor White
Write-Host ""
