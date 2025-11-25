<#
.SYNOPSIS
    Generate individual article outlines from a topic cluster plan
.DESCRIPTION
    Creates outline files with delays between requests to avoid rate limits.
    Uses correct Gemini CLI syntax for file context.
.PARAMETER SeriesName
    The series/plan name (folder name under plans/)
.PARAMETER Count
    Optional: Number of outlines to generate
.PARAMETER IncludePillar
    Include the pillar article in outline generation
.PARAMETER DelaySeconds
    Delay between API calls in seconds (default: 3)
.PARAMETER ShowDebug
    Enable verbose debug output
.PARAMETER SaveDebugLog
    Save debug information to a log file
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SeriesName,

    [Parameter(Mandatory=$false)]
    [int]$Count = 0,

    [Parameter(Mandatory=$false)]
    [switch]$IncludePillar,

    [Parameter(Mandatory=$false)]
    [int]$DelaySeconds = 3,

    [Parameter(Mandatory=$false)]
    [switch]$ShowDebug,

    [Parameter(Mandatory=$false)]
    [switch]$SaveDebugLog
)

# Helper function to clean Gemini CLI output
function Clean-GeminiOutput {
    param([string]$RawOutput)

    # Split into lines
    $Lines = $RawOutput -split "`r?`n"

    # Filter out debug/status messages
    $CleanLines = $Lines | Where-Object {
        $_ -notmatch '^Loaded cached credentials' -and
        $_ -notmatch '^Loading' -and
        $_ -notmatch '^Initializing' -and
        $_ -notmatch '^Using model' -and
        $_ -notmatch '^Gemini CLI' -and
        $_ -notmatch '^Generating content' -and
        $_ -notmatch '^Streaming' -and
        $_ -notmatch '^Connected to' -and
        $_ -notmatch '^Unknown argument' -and
        $_ -ne ''
    }

    # Remove leading empty lines
    while ($CleanLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($CleanLines[0])) {
        $CleanLines = $CleanLines[1..($CleanLines.Count - 1)]
    }

    # Rejoin and trim
    $CleanOutput = ($CleanLines -join "`n").Trim()

    return $CleanOutput
}

# Helper function for debug logging
function Write-DebugInfo {
    param(
        [string]$Message,
        [string]$Detail = "",
        [string]$Color = "Gray"
    )

    if ($ShowDebug) {
        Write-Host "[DEBUG] $Message" -ForegroundColor $Color
        if ($Detail) {
            Write-Host "        $Detail" -ForegroundColor DarkGray
        }
    }

    if ($SaveDebugLog) {
        $LogMessage = "$(Get-Date -Format 'HH:mm:ss') - $Message"
        if ($Detail) {
            $LogMessage += "`n        $Detail"
        }
        Add-Content -Path $DebugLogFile -Value $LogMessage -Encoding UTF8
    }
}

$PlanDir = "plans/$SeriesName"
$PlanFile = "$PlanDir/_plan.md"
$OutlinesDir = "$PlanDir/outlines"
$DebugLogFile = "$PlanDir/debug-outlines.log"

# Initialize debug log if requested
if ($SaveDebugLog) {
    $LogHeader = @"
# Debug Log: Generate Outlines
Series: $SeriesName
Started: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Parameters:
  - Count: $Count
  - IncludePillar: $IncludePillar
  - DelaySeconds: $DelaySeconds
  - ShowDebug: $ShowDebug

---

"@
    Set-Content -Path $DebugLogFile -Value $LogHeader -Encoding UTF8
    Write-Host "Debug log will be saved to: $DebugLogFile" -ForegroundColor Yellow
}

if (-not (Test-Path $PlanFile)) {
    Write-Error "Plan file not found: $PlanFile"
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Generating Article Outlines (Rate-Limited)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Read and verify plan
Write-DebugInfo "Reading plan file: $PlanFile"
$PlanContent = Get-Content $PlanFile -Raw
Write-DebugInfo "Plan file size: $($PlanContent.Length) characters"

# Check if plan has debug messages
if ($PlanContent -match 'Loaded cached credentials') {
    Write-Error "Plan file contains debug messages. Please regenerate the plan."
    Write-Host "Run: .\scripts\New-TopicCluster.ps1 -Topic 'Your Topic' -SeriesName $SeriesName" -ForegroundColor Yellow
    exit 1
}

# Show plan preview in debug mode
if ($ShowDebug) {
    Write-Host ""
    Write-Host "Plan Preview (first 500 chars):" -ForegroundColor Yellow
    Write-Host ($PlanContent.Substring(0, [Math]::Min(500, $PlanContent.Length))) -ForegroundColor DarkGray
    Write-Host ""
}

# Determine article count
$TotalArticles = 0
if ($PlanContent -match '\*\*Article Count:\*\*\s*(\d+)') {
    $TotalArticles = [int]$Matches[1]
    Write-DebugInfo "Found article count in metadata: $TotalArticles"
} elseif ($PlanContent -match 'ARTICLE_COUNT:\s*(\d+)') {
    $TotalArticles = [int]$Matches[1]
    Write-DebugInfo "Found ARTICLE_COUNT marker: $TotalArticles"
} else {
    $ArticleMatches = [regex]::Matches($PlanContent, '\*\*Article\s+(\d+):', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($ArticleMatches.Count -gt 0) {
        $TotalArticles = ($ArticleMatches | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
        Write-DebugInfo "Counted articles by pattern matching: $TotalArticles"
    }
}

if ($TotalArticles -eq 0 -and $Count -eq 0) {
    Write-Error "Could not determine article count. Use -Count parameter."
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check if plan contains 'Article 1:', 'Article 2:', etc." -ForegroundColor Gray
    Write-Host "  2. Manually specify: -Count [number]" -ForegroundColor Gray
    Write-Host "  3. Review plan file: code $PlanFile" -ForegroundColor Gray
    exit 1
}

if ($Count -gt 0) {
    $TotalArticles = $Count
    Write-DebugInfo "Using manually specified count: $TotalArticles"
}

Write-Host "Plan: $SeriesName" -ForegroundColor Yellow
Write-Host "Articles to Generate: $TotalArticles" -ForegroundColor Yellow
Write-Host "Delay Between Requests: ${DelaySeconds}s" -ForegroundColor Yellow
Write-Host ""

# Test Gemini CLI before starting
Write-DebugInfo "Testing Gemini CLI connection..."
try {
    $TestOutput = & gemini "test" 2>&1 | Out-String
    Write-DebugInfo "Gemini CLI test successful" "Output length: $($TestOutput.Length)"
} catch {
    Write-Error "Gemini CLI test failed: $($_.Exception.Message)"
    Write-Host "Check: gemini --version" -ForegroundColor Yellow
    exit 1
}

# Generate pillar if requested
if ($IncludePillar) {
    Write-Host "Generating Pillar Article outline..." -ForegroundColor Green
    $PillarFile = "$OutlinesDir/00-pillar.md"

    # Build combined prompt with plan context
    $PillarPromptWithContext = @"
Using the following content plan as context:

--- PLAN START ---
$PlanContent
--- PLAN END ---

Create a brief outline for the main pillar article based on this plan.

Include:
- Title
- Description (2-3 sentences)
- 3-5 main sections
- How it ties all supporting articles together

Keep it concise (under 400 words).
"@

    Write-DebugInfo "Pillar prompt length: $($PillarPromptWithContext.Length)"

    try {
        $RawOutput = & gemini $PillarPromptWithContext 2>&1 | Out-String
        Write-DebugInfo "Pillar raw output length: $($RawOutput.Length)"

        $PillarOutput = Clean-GeminiOutput -RawOutput $RawOutput
        Write-DebugInfo "Pillar cleaned output length: $($PillarOutput.Length)"

        if (-not [string]::IsNullOrWhiteSpace($PillarOutput)) {
            Set-Content -Path $PillarFile -Value $PillarOutput -Encoding UTF8
            Write-Host "✓ Pillar outline created" -ForegroundColor Green
        } else {
            Write-Warning "Empty pillar output after cleaning"
        }

        Start-Sleep -Seconds $DelaySeconds
    } catch {
        Write-Warning "Could not generate pillar outline: $($_.Exception.Message)"
        Write-DebugInfo "Pillar generation error" $_.Exception.Message "Red"
    }
    Write-Host ""
}

# Track successes and failures
$SuccessCount = 0
$FailureCount = 0
$FailedArticles = @()

# Generate supporting articles
for ($i = 1; $i -le $TotalArticles; $i++) {
    $OutlineFile = "$OutlinesDir/{0:D2}-article-{0}.md" -f $i

    Write-Host "[$($i)/$($TotalArticles)] Generating outline for Article $($i)..." -ForegroundColor Green
    Write-DebugInfo "Processing Article $($i)" "Output file: $OutlineFile"

    # Build combined prompt with plan context embedded
    $OutlinePromptWithContext = @"
Using the following content plan as context:

--- PLAN START ---
$PlanContent
--- PLAN END ---

From the plan above, create a brief outline for Article $($i).

Include:
- Title (extract from plan or create appropriate title)
- Description (1-2 sentences)
- 3-5 main section headings
- Key points to cover (3-5 bullets)

Keep it concise (under 300 words).
"@

    Write-DebugInfo "Outline prompt for Article $($i)" "Prompt length: $($OutlinePromptWithContext.Length)"

    try {
        # Capture raw output with timing
        $StartTime = Get-Date
        Write-DebugInfo "Calling Gemini CLI..."

        $RawOutput = & gemini $OutlinePromptWithContext 2>&1 | Out-String

        $ElapsedSeconds = ((Get-Date) - $StartTime).TotalSeconds
        Write-DebugInfo "Gemini CLI call completed" "Time: ${ElapsedSeconds}s, Exit code: $LASTEXITCODE"
        Write-DebugInfo "Raw output length: $($RawOutput.Length)"

        # Show raw output in debug mode
        if ($ShowDebug) {
            Write-Host "  Raw output preview (first 200 chars):" -ForegroundColor DarkGray
            Write-Host "  $($RawOutput.Substring(0, [Math]::Min(200, $RawOutput.Length)))" -ForegroundColor DarkGray
        }

        # Clean output
        $OutlineOutput = Clean-GeminiOutput -RawOutput $RawOutput
        Write-DebugInfo "Cleaned output length: $($OutlineOutput.Length)"

        # Check for specific error patterns
        if ($RawOutput -match '429|rate limit|quota') {
            Write-Warning "  ⚠ Rate limit detected. Increasing delay..."
            Write-DebugInfo "Rate limit error detected" "Waiting longer..." "Yellow"
            Start-Sleep -Seconds ($DelaySeconds * 3)

            # Retry once
            Write-Host "  Retrying Article $($i)..." -ForegroundColor Yellow
            $RawOutput = & gemini $OutlinePromptWithContext 2>&1 | Out-String
            $OutlineOutput = Clean-GeminiOutput -RawOutput $RawOutput
        }

        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($OutlineOutput)) {
            # Add Hugo front matter
            $FrontMatter = @"
---
title: "Article $($i)"
date: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
draft: true
series: ["$SeriesName"]
weight: $($i)
---

"@

            $FullOutline = $FrontMatter + $OutlineOutput
            Set-Content -Path $OutlineFile -Value $FullOutline -Encoding UTF8

            Write-Host "  ✓ Outline created: $OutlineFile" -ForegroundColor Green
            Write-Host "    Preview: $($OutlineOutput.Substring(0, [Math]::Min(100, $OutlineOutput.Length)))..." -ForegroundColor DarkGray

            Write-DebugInfo "Article $($i) SUCCESS" "File: $OutlineFile, Size: $($FullOutline.Length)" "Green"
            $SuccessCount++
        } else {
            Write-Warning "  ⚠ Failed to generate outline $($i) (empty output)"
            Write-DebugInfo "Article $($i) FAILED - Empty output" "Exit code: $LASTEXITCODE, Raw length: $($RawOutput.Length)" "Red"

            # Detailed diagnostics
            Write-Host ""
            Write-Host "  Diagnostics for Article $($i):" -ForegroundColor Yellow
            Write-Host "    Exit Code: $LASTEXITCODE" -ForegroundColor Gray
            Write-Host "    Raw Output Length: $($RawOutput.Length)" -ForegroundColor Gray
            Write-Host "    Cleaned Output Length: $($OutlineOutput.Length)" -ForegroundColor Gray

            if ($RawOutput.Length -gt 0) {
                Write-Host "    Raw Output Sample:" -ForegroundColor Gray
                Write-Host "    $($RawOutput.Substring(0, [Math]::Min(300, $RawOutput.Length)))" -ForegroundColor DarkGray
            }

            Write-Host ""
            Write-Host "  Possible causes:" -ForegroundColor Yellow
            Write-Host "    1. Rate limiting (429 error)" -ForegroundColor Gray
            Write-Host "    2. Plan context too large for single request" -ForegroundColor Gray
            Write-Host "    3. Article $($i) not clearly defined in plan" -ForegroundColor Gray
            Write-Host "    4. API timeout or network issue" -ForegroundColor Gray
            Write-Host ""

            # Create placeholder with diagnostics
            $Placeholder = @"
---
title: "Article $($i) - Generation Failed"
date: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
draft: true
series: ["$SeriesName"]
weight: $($i)
---

# Article $($i) - Manual Editing Required

**Generation failed at:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

**Diagnostics:**
- Exit Code: $LASTEXITCODE
- Raw Output Length: $($RawOutput.Length)
- Cleaned Output Length: $($OutlineOutput.Length)

**Next Steps:**
1. Check if Article $($i) exists in plan: $PlanFile
2. Wait 10-15 minutes for rate limits to reset
3. Retry with longer delay: .\scripts\Generate-Outlines.ps1 -SeriesName $SeriesName -DelaySeconds 15
4. Manually create outline based on plan

**Raw Output (first 500 chars):**
$($RawOutput.Substring(0, [Math]::Min(500, $RawOutput.Length)))
"@
            Set-Content -Path $OutlineFile -Value $Placeholder -Encoding UTF8

            $FailureCount++
            $FailedArticles += $i
        }

        # Delay before next request (except last)
        if ($i -lt $TotalArticles) {
            Write-Host "  Waiting ${DelaySeconds}s..." -ForegroundColor DarkGray
            Write-DebugInfo "Sleeping for ${DelaySeconds}s before next request"
            Start-Sleep -Seconds $DelaySeconds
        }

    } catch {
        Write-Warning "  ✗ Error generating outline $($i): $($_.Exception.Message)"
        Write-DebugInfo "Article $($i) EXCEPTION" $_.Exception.Message "Red"

        # Create error placeholder
        $ErrorPlaceholder = @"
---
title: "Article $($i) - Error"
date: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
draft: true
series: ["$SeriesName"]
weight: $($i)
---

# Article $($i) - Error During Generation

**Error:** $($_.Exception.Message)

**Time:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Please regenerate or create manually.
"@
        Set-Content -Path $OutlineFile -Value $ErrorPlaceholder -Encoding UTF8

        $FailureCount++
        $FailedArticles += $i
    }

    Write-Host ""
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Outline Generation Complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Summary
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Total Articles: $TotalArticles" -ForegroundColor White
Write-Host "  Successful: $SuccessCount" -ForegroundColor Green
Write-Host "  Failed: $FailureCount" -ForegroundColor Red

if ($FailureCount -gt 0) {
    Write-Host ""
    Write-Host "Failed Articles: $($FailedArticles -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting Steps:" -ForegroundColor Yellow
    Write-Host "  1. Wait 10-15 minutes for rate limits to reset" -ForegroundColor Gray
    Write-Host "  2. Increase delay significantly: -DelaySeconds 15" -ForegroundColor Gray
    Write-Host "  3. Check plan file: code $PlanFile" -ForegroundColor Gray
    Write-Host "  4. Review debug log: code $DebugLogFile" -ForegroundColor Gray
    Write-Host "  5. Manually edit placeholders in: $OutlinesDir" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review outlines: code $OutlinesDir" -ForegroundColor White
Write-Host "  2. Edit failed outlines manually if needed" -ForegroundColor White
Write-Host "  3. Promote to content: .\scripts\Promote-Outline.ps1 -SeriesName $SeriesName -Number 1" -ForegroundColor White
Write-Host ""

if ($SaveDebugLog) {
    Write-Host "Debug log saved to: $DebugLogFile" -ForegroundColor Yellow
    Write-Host ""
}
