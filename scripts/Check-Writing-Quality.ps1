<#
.SYNOPSIS
    Check article for AI writing patterns and banned phrases
.DESCRIPTION
    Scans article for common AI writing patterns, banned phrases, and style issues
    from the words-not-to-use guidelines
.PARAMETER Slug
    The article slug to check
.PARAMETER ShowAll
    Show all issues including low-priority ones
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowAll
)

# Logic to determine path: check for bundle first, then standalone file
$BundlePath = "content/posts/$Slug/index.md"
$StandalonePath = "content/posts/$Slug.md"

if (Test-Path $BundlePath) {
    $ArticlePath = $BundlePath
    Write-Host "Checking article bundle: $ArticlePath" -ForegroundColor Gray
} elseif (Test-Path $StandalonePath) {
    $ArticlePath = $StandalonePath
    Write-Host "Checking standalone article: $ArticlePath" -ForegroundColor Gray
} else {
    Write-Error "Article not found: $Slug"
    exit 1
}

$Content = Get-Content $ArticlePath -Raw

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Writing Quality Check" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Banned phrases
$BannedPhrases = @{
    'delve|delving' = 'Use: explore, examine, analyze'
    'leverage|leveraging' = 'Use: use, apply'
    '\brobust\b' = 'Use: reliable, stable, production-ready'
    'seamless|seamlessly' = 'Use: smooth, integrated'
    'cutting-edge' = 'Use: modern, current, latest'
    'game-changer' = 'Use: improves, transforms'
    'in the realm of' = 'Remove: start with subject directly'
    'when it comes to' = 'Remove: start with subject directly'
    'at the end of the day' = 'Use: ultimately, finally'
    "let's dive into" = 'Remove: start topic directly'
    "it's worth noting" = 'Remove: just state the fact'
    'empower|empowering' = 'Use: enable, help, allow'
    'unlock' = 'Use: enable, access, reveal'
    'harness' = 'Use: use, apply'
    'tap into' = 'Use: use, access'
}

$Issues = @()

foreach ($Pattern in $BannedPhrases.Keys) {
    $Matches = [regex]::Matches($Content, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($Matches.Count -gt 0) {
        $Issues += [PSCustomObject]@{
            Severity = 'HIGH'
            Type = 'Banned Phrase'
            Pattern = $Pattern
            Count = $Matches.Count
            Suggestion = $BannedPhrases[$Pattern]
        }
    }
}

# Vague qualifiers
$VaguePatterns = @(
    'very \w+',
    'quite \w+',
    'really \w+',
    'extremely \w+',
    'highly \w+',
    'significantly',
    'considerably',
    'substantially'
)

foreach ($Pattern in $VaguePatterns) {
    $Matches = [regex]::Matches($Content, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($Matches.Count -gt 0 -and $ShowAll) {
        $Issues += [PSCustomObject]@{
            Severity = 'MEDIUM'
            Type = 'Vague Qualifier'
            Pattern = $Pattern
            Count = $Matches.Count
            Suggestion = 'Be specific with numbers or concrete descriptions'
        }
    }
}

# Display results
if ($Issues.Count -eq 0) {
    Write-Host "✓ No major writing issues found!" -ForegroundColor Green
} else {
    $HighIssues = $Issues | Where-Object { $_.Severity -eq 'HIGH' }
    $MediumIssues = $Issues | Where-Object { $_.Severity -eq 'MEDIUM' }
    
    if ($HighIssues) {
        Write-Host "✗ HIGH Priority Issues:" -ForegroundColor Red
        foreach ($Issue in $HighIssues) {
            Write-Host "  [$($Issue.Type)] '$($Issue.Pattern)' found $($Issue.Count) time(s)" -ForegroundColor Red
            Write-Host "    → $($Issue.Suggestion)" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    if ($MediumIssues -and $ShowAll) {
        Write-Host "⚠ Medium Priority Issues:" -ForegroundColor Yellow
        foreach ($Issue in $MediumIssues) {
            Write-Host "  [$($Issue.Type)] '$($Issue.Pattern)' found $($Issue.Count) time(s)" -ForegroundColor Yellow
            Write-Host "    → $($Issue.Suggestion)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

Write-Host "For complete guidelines, see:" -ForegroundColor Cyan
Write-Host "  .gemini/writing-guidelines/words-not-to-use.md" -ForegroundColor Gray
Write-Host ""
