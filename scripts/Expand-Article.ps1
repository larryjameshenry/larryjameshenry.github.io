<#
.SYNOPSIS
    Expand article with quality-focused approach
.DESCRIPTION
    Balances quality and rate limits. Uses context-aware expansion.
.PARAMETER Slug
    The article slug
.PARAMETER Mode
    Expansion mode: Quality (default), Conservative, or Minimal
.PARAMETER SkipBackup
    Skip backup
.PARAMETER DelaySeconds
    Delay between requests (default varies by mode)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Quality', 'Conservative', 'Minimal')]
    [string]$Mode = 'Quality',

    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup,

    [Parameter(Mandatory=$false)]
    [int]$DelaySeconds = 0
)

# Set defaults based on mode
if ($DelaySeconds -eq 0) {
    switch ($Mode) {
        'Quality' { $DelaySeconds = 8 }
        'Conservative' { $DelaySeconds = 15 }
        'Minimal' { $DelaySeconds = 20 }
    }
}

function Clean-GeminiOutput {
    param([string]$RawOutput)

    $Lines = $RawOutput -split "`r?`n"
    $CleanLines = $Lines | Where-Object {
        $_ -notmatch '^(Loaded cached credentials|Loading|Initializing|Using model|Gemini CLI|Generating content|Streaming|Connected to|Attempt \d+ failed)'
    }

    while ($CleanLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($CleanLines[0])) {
        $CleanLines = $CleanLines[1..($CleanLines.Count - 1)]
    }

    return ($CleanLines -join "`n").Trim()
}

function Invoke-GeminiWithRetry {
    param(
        [string]$Prompt,
        [int]$MaxRetries = 3,
        [int]$BaseDelay = 10
    )

    $Attempt = 1

    while ($Attempt -le $MaxRetries) {
        try {
            $Result = & gemini $Prompt 2>&1 | Out-String

            if ($Result -match '429|rate limit|quota|Resource exhausted') {
                throw "Rate limit detected"
            }

            if ($LASTEXITCODE -eq 0) {
                return Clean-GeminiOutput -RawOutput $Result
            }

            throw "Exit code $LASTEXITCODE"

        } catch {
            if ($Attempt -lt $MaxRetries) {
                $WaitTime = $BaseDelay * ([Math]::Pow(2, $Attempt - 1))  # 10s, 20s, 40s
                Write-Host "  ⚠ Rate limit, waiting $($WaitTime)s (retry $($Attempt + 1)/$MaxRetries)..." -ForegroundColor Yellow
                Start-Sleep -Seconds $WaitTime
                $Attempt++
            } else {
                return $null
            }
        }
    }

    return $null
}

# Find article
$BundlePath = "content/posts/$Slug/index.md"
$SingleFilePath = "content/posts/$Slug.md"

if (Test-Path $BundlePath) {
    $ArticlePath = $BundlePath
    $IsBundle = $true
} elseif (Test-Path $SingleFilePath) {
    $ArticlePath = $SingleFilePath
    $IsBundle = $false
} else {
    Write-Error "Article not found: $Slug"
    exit 1
}

$CurrentContent = Get-Content $ArticlePath -Raw

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Article Expansion - $Mode Mode" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Article: $Slug" -ForegroundColor Yellow
Write-Host "Mode: $Mode" -ForegroundColor Yellow
Write-Host "Delay: ${DelaySeconds}s" -ForegroundColor Yellow
Write-Host ""

# Backup
if (-not $SkipBackup) {
    $BackupDir = "backups"
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }

    $BackupFile = "$BackupDir/$Slug-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    Copy-Item $ArticlePath $BackupFile -Force
    Write-Host "✓ Backup: $BackupFile" -ForegroundColor Green
    Write-Host ""
}

try {
    # Extract parts
    $FrontMatter = ""
    $OutlineContent = $CurrentContent

    if ($CurrentContent -match '(?s)^(---.*?---)\s*(.*)') {
        $FrontMatter = $Matches[1]
        $OutlineContent = $Matches[2].Trim()
    }

    $ArticleTitle = "this article"
    if ($FrontMatter -match 'title:\s*["\x27]?([^"\x27\r\n]+)') {
        $ArticleTitle = $Matches[1]
    }

    # STRATEGY: Group related sections for better context
    Write-Host "Analyzing outline structure..." -ForegroundColor Cyan

    $Sections = @()
    $CurrentSection = ""
    $SectionTitle = ""

    foreach ($Line in ($OutlineContent -split "`r?`n")) {
        if ($Line -match '^#{2,3}\s+(.+)') {
            if ($CurrentSection) {
                $Sections += @{
                    Title = $SectionTitle
                    Content = $CurrentSection.Trim()
                    Level = ($Line -match '^#{2}\s+') ? 2 : 3
                }
            }
            $SectionTitle = $Matches[1]
            $CurrentSection = "$Line`n"
        } else {
            $CurrentSection += "$Line`n"
        }
    }

    if ($CurrentSection) {
        $Sections += @{
            Title = $SectionTitle
            Content = $CurrentSection.Trim()
            Level = 2
        }
    }

    Write-Host "Found $($Sections.Count) sections" -ForegroundColor Gray
    Write-Host ""

    # Group sections into logical chunks based on mode
    $Chunks = switch ($Mode) {
        'Quality' {
            # Larger chunks (2-3 sections) for better context
            $Groups = @()
            for ($i = 0; $i -lt $Sections.Count; $i += 2) {
                $Group = $Sections[$i]
                if ($i + 1 -lt $Sections.Count) {
                    $Group.Content += "`n`n" + $Sections[$i + 1].Content
                    $Group.Title += " + " + $Sections[$i + 1].Title
                }
                $Groups += $Group
            }
            $Groups
        }
        'Conservative' {
            # Single sections
            $Sections
        }
        'Minimal' {
            # Split large sections
            $Split = @()
            foreach ($Section in $Sections) {
                if ($Section.Content.Length -gt 500) {
                    # Split at paragraph breaks
                    $Paras = $Section.Content -split "`n`n"
                    $CurrentChunk = ""
                    foreach ($Para in $Paras) {
                        if ($CurrentChunk.Length + $Para.Length -gt 500 -and $CurrentChunk) {
                            $Split += @{ Title = $Section.Title; Content = $CurrentChunk }
                            $CurrentChunk = $Para
                        } else {
                            $CurrentChunk += "`n`n" + $Para
                        }
                    }
                    if ($CurrentChunk) {
                        $Split += @{ Title = $Section.Title; Content = $CurrentChunk }
                    }
                } else {
                    $Split += $Section
                }
            }
            $Split
        }
    }

    Write-Host "Expansion plan: $($Chunks.Count) requests" -ForegroundColor Yellow
    Write-Host "Estimated time: $([Math]::Round($Chunks.Count * $DelaySeconds / 60, 1)) minutes" -ForegroundColor Gray
    Write-Host ""

    # Word count targets based on mode
    $WordTarget = switch ($Mode) {
        'Quality' { '400-600' }
        'Conservative' { '250-400' }
        'Minimal' { '150-250' }
    }

    # Build comprehensive context once
    $WritingContext = @"
ARTICLE CONTEXT:
Title: $ArticleTitle
Target Audience: Technical readers
Style: Professional but conversational

QUALITY REQUIREMENTS:
- NO AI clichés: avoid "delve", "leverage", "robust", "seamless", "cutting-edge"
- NO vague phrases: "in the realm of", "when it comes to", "at the end of the day"
- USE specific numbers, metrics, and examples
- INCLUDE working code examples with explanatory comments
- SHOW expected output for code examples
- EXPLAIN WHY, not just HOW
- USE active voice and direct statements

CODE STYLE:
- Add comments explaining what code does and why
- Use realistic variable names
- Include error handling where appropriate
- Show expected output as comments
"@

    # Expand chunks
    $ExpandedChunks = @()
    $ChunkNum = 1

    foreach ($Chunk in $Chunks) {
        Write-Host "[$ChunkNum/$($Chunks.Count)] Expanding: $($Chunk.Title)" -ForegroundColor Green

        $ExpansionPrompt = @"
$WritingContext

TARGET: $WordTarget words

EXPAND THIS SECTION:
$($Chunk.Content)

Generate detailed, high-quality content with:
- Specific examples and metrics (not vague claims)
- Code examples with comments (if relevant)
- Clear explanations with real-world context
- Natural, engaging writing (avoid AI clichés)

Maintain the heading structure from the outline.
"@

        $Expanded = Invoke-GeminiWithRetry -Prompt $ExpansionPrompt -MaxRetries 3 -BaseDelay $DelaySeconds

        if ([string]::IsNullOrWhiteSpace($Expanded)) {
            Write-Warning "  Failed, using outline"
            $Expanded = $Chunk.Content
        } else {
            Write-Host "  ✓ Complete ($($Expanded.Length) chars)" -ForegroundColor Green
        }

        $ExpandedChunks += $Expanded

        if ($ChunkNum -lt $Chunks.Count) {
            Write-Host "  Waiting ${DelaySeconds}s..." -ForegroundColor DarkGray
            Start-Sleep -Seconds $DelaySeconds
        }

        Write-Host ""
        $ChunkNum++
    }

    # Generate strong intro and conclusion with full context
    Write-Host "Generating introduction..." -ForegroundColor Cyan

    $IntroPrompt = @"
$WritingContext

Write a compelling introduction (200-250 words) for: $ArticleTitle

OUTLINE PREVIEW:
$($Sections[0..2] | ForEach-Object { "- " + $_.Title } | Join-String -Separator "`n")

Include:
1. Hook: Start with specific problem, surprising fact, or real scenario
2. Context: Why this matters (with specifics, not vague claims)
3. Promise: What reader will learn (be concrete - "3 optimization techniques" not "learn to optimize")
4. Preview: Brief roadmap of main points

NO generic phrases. Be specific and engaging.
"@

    $Intro = Invoke-GeminiWithRetry -Prompt $IntroPrompt -MaxRetries 3 -BaseDelay $DelaySeconds

    if ([string]::IsNullOrWhiteSpace($Intro)) {
        $Intro = "# Introduction`n`n[Manual intro needed]"
    } else {
        Write-Host "✓ Introduction ($($Intro.Length) chars)" -ForegroundColor Green
    }

    Start-Sleep -Seconds $DelaySeconds
    Write-Host ""

    Write-Host "Generating conclusion..." -ForegroundColor Cyan

    $ConclusionPrompt = @"
$WritingContext

Write a strong conclusion (200-250 words) for: $ArticleTitle

ARTICLE COVERED:
$($Sections | ForEach-Object { "- " + $_.Title } | Join-String -Separator "`n")

Include:
1. Summary: 5 specific, actionable takeaways (be concrete)
2. Next Steps: What reader should do next (specific actions)
3. Further Learning: Related topics to explore

NO generic closing phrases. End with confidence and clarity.
"@

    $Conclusion = Invoke-GeminiWithRetry -Prompt $ConclusionPrompt -MaxRetries 3 -BaseDelay $DelaySeconds

    if ([string]::IsNullOrWhiteSpace($Conclusion)) {
        $Conclusion = "## Conclusion`n`n[Manual conclusion needed]"
    } else {
        Write-Host "✓ Conclusion ($($Conclusion.Length) chars)" -ForegroundColor Green
    }

    Write-Host ""

    # Combine
    $Combined = $Intro + "`n`n" + ($ExpandedChunks -join "`n`n") + "`n`n" + $Conclusion

    # Update front matter
    if ($FrontMatter -match 'draft:\s*true') {
        $FrontMatter = $FrontMatter -replace 'draft:\s*true', 'draft: false'
    }

    $Final = $FrontMatter + "`n`n" + $Combined

    Set-Content -Path $ArticlePath -Value $Final -Encoding UTF8 -NoNewline

    $WordCount = ($Final -split '\s+').Count

    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Article Expanded Successfully!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Quality Score: " -NoNewline -ForegroundColor Yellow

    $QualityIndicators = @(
        ($Combined -notmatch 'delve|leverage|robust|seamless'),
        ($Combined -match '\d+%|\d+x|\d+ users|\$\d+'),
        ($Combined -match '```'),
        ($WordCount -ge 1500)
    )
    $QualityScore = ($QualityIndicators | Where-Object { $_ }).Count

    $ScoreColor = "Red"
    if ($QualityScore -ge 3) { $ScoreColor = "Green" }
    if ($QualityScore -ge 2) { $ScoreColor = "Yellow" }


    Write-Host "$QualityScore/4" -ForegroundColor $ScoreColor

    $Indicator1Color = if($QualityIndicators[0]) { 'Green' } else { 'Yellow' }
    Write-Host "  ✓ No AI clichés: $(if($QualityIndicators[0]){'Yes'}else{'CHECK'})" -ForegroundColor $Indicator1Color

    $Indicator2Color = if($QualityIndicators[1]) { 'Green' } else { 'Yellow' }
    Write-Host "  ✓ Specific metrics: $(if($QualityIndicators[1]){'Yes'}else{'CHECK'})" -ForegroundColor $Indicator2Color

    $Indicator3Color = if($QualityIndicators[2]) { 'Green' } else { 'Yellow' }
    Write-Host "  ✓ Code examples: $(if($QualityIndicators[2]){'Yes'}else{'CHECK'})" -ForegroundColor $Indicator3Color

    $Indicator4Color = if($QualityIndicators[3]) { 'Green' } else { 'Yellow' }
    Write-Host "  ✓ Word count: $WordCount $(if($WordCount -ge 1500){'✓'}else{'(short)'})" -ForegroundColor $Indicator4Color
    Write-Host ""

    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Review: code $ArticlePath" -ForegroundColor White
    Write-Host "  2. Polish manually: Add more examples, metrics, code" -ForegroundColor White
    Write-Host "  3. Test: hugo server --buildDrafts" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Error "Failed: $($_.Exception.Message)"
    exit 1
}
