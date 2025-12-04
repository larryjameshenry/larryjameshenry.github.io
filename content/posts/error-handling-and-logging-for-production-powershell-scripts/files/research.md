This comprehensive research report covers robust error handling and logging for production PowerShell scripts, tailored for intermediate scripters and DevOps engineers.

# Robust Error Handling and Logging for Production PowerShell Scripts

## 1. Executive Summary & User Intent

*   **Core Definition:** Robust error handling and logging in PowerShell involves explicitly managing script failures to prevent silent data corruption or cascading errors, and recording structured activity data to facilitate rapid debugging and auditing.
*   **User Intent:** The reader seeks to elevate their scripting from "it works on my machine" to "enterprise-grade automation." They want to know *how* to stop scripts safely when things break, *how* to capture meaningful logs without flooding disk space, and *which* modern tools (like PowerShell 7 features) they should be using.
*   **Relevance:** As infrastructure-as-code and CI/CD pipelines become standard, flaky scripts are a major liability. Production scripts must be observable, resilient, and easy to debug remotely.

## 2. Key Technical Concepts & "All-Inclusive" Details

### Core Components
*   **Terminating Errors:** Errors that halt the pipeline or script immediately (e.g., syntax errors, explicit `Throw`).
*   **Non-Terminating Errors:** Errors that allow the script to continue to the next command (e.g., `Get-ChildItem` on a missing file).
*   **ErrorActionPreference:** A global or local variable determining how non-terminating errors are treated.
*   **Streams:** PowerShell has multiple output streams. Success is Stream 1, Error is Stream 2. Logging often involves redirecting these streams.

### Key Terminology
*   **`$?`**: A boolean automatic variable containing the execution status of the last operation (`True` = success, `False` = failure).
*   **`$Error`**: An automatic array variable containing a history of errors in the session (index `[0]` is the most recent).
*   **Structured Logging:** Writing logs in a machine-parsable format (like JSON) rather than unstructured text lines.

## 3. Practical Implementation (The "Solid" Part)

### Standard Pattern: The Try/Catch/Finally Block
This is the gold standard for handling terminating errors. You **must** force non-terminating errors to be terminating for `Catch` to work.

```powershell
function Invoke-ProductionTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    # "Stop" forces non-terminating errors (like file not found) to be caught
    $ErrorActionPreference = 'Stop'

    try {
        Write-Verbose "Starting task processing for $FilePath"
        
        # Validation logic
        if (-not (Test-Path -Path $FilePath)) {
            throw [System.IO.FileNotFoundException] "Critical: File $FilePath not found."
        }

        # Dangerous operation
        $content = Get-Content -Path $FilePath -Raw
        Write-Output "Successfully read $($content.Length) bytes."
    }
    catch [System.IO.FileNotFoundException] {
        # Handle specific known errors first
        Write-Error "Missing File Error: $($_.Exception.Message)"
        # Optional: Retry logic could go here
    }
    catch {
        # Catch-all for unexpected errors
        $errorMessage = $_.Exception.Message
        $failedCommand = $_.InvocationInfo.MyCommand
        Write-Error "Unexpected Crash in $failedCommand : $errorMessage"
        
        # Log detailed error to file/system
        # Log-Error -Message $errorMessage -Detail $_
    }
    finally {
        # Cleanup runs regardless of success or failure
        Write-Verbose "Cleaning up resources..."
        # Close-Connection $conn
    }
}
```

### Comprehensive Logging Strategy
Do not rely solely on `Start-Transcript`. It is unstructured and hard to query. Use a custom wrapper or structured logging.

**Recommended Pattern: JSON Structured Logging**
Writing logs as JSON allows tools like Splunk, Azure Log Analytics, or CloudWatch to ingest and query them easily.

```powershell
function Write-Log {
    param (
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','DEBUG')]
        [string]$Level = 'INFO',
        [hashtable]$Data = @{}
    )

    $logEntry = [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        Level     = $Level
        Message   = $Message
        Host      = $env:COMPUTERNAME
        User      = $env:USERNAME
        Data      = $Data # Contextual data (e.g., FileID, ServerName)
    }

    # Output as single-line JSON for easy ingestion
    $logEntry | ConvertTo-Json -Compress | Out-File -FilePath "C:\Logs\app.json" -Append -Encoding utf8
}

# Usage
Write-Log -Message "Processing failed" -Level "ERROR" -Data @{ FileID = 102; RetryCount = 3 }
```

### Script Modularity & Validation
Scripts should be broken into Functions, and those Functions should be grouped into Modules (`.psm1`).

**Advanced Parameter Validation:**
Fail fast before the script even runs logic.

```powershell
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path $_ -PathType Leaf })] # Fails if file doesn't exist
    [string]$ConfigurationFile,

    [Parameter(Mandatory)]
    [ValidateSet('Dev', 'Stage', 'Prod')]
    [string]$Environment
)
```

## 4. Best Practices vs. Anti-Patterns

| Feature | **Do This (Best Practice)** | **Don't Do This (Anti-Pattern)** |
| :--- | :--- | :--- |
| **Error Handling** | Use `Try/Catch` with `$ErrorActionPreference = 'Stop'` inside the function/script scope. | Checking `if ($?)` after every single command. |
| **Output** | Use `Write-Verbose` for debug info and `Write-Warning` for non-critical issues. | Use `Write-Host` for everything (cannot be captured easily). |
| **Logging** | Log "Why" and "Context" (User, Machine, Data ID) in structured formats (JSON). | Log "What happened" in plain text (e.g., "Error 5 occurred"). |
| **Recovery** | Clean up connections/files in a `Finally` block. | Rely on the script finishing to clean up resources. |
| **Exceptions** | Throw specific typed exceptions (e.g., `[System.ArgumentException]`). | Just using `throw "it failed"`. |

## 5. Edge Cases & Troubleshooting

*   **The `Trap` Statement:** An older keyword similar to `Catch`. **Avoid using it** in modern scripts; strictly prefer `Try/Catch`.
*   **Pipeline Errors:** Errors inside a pipeline can be tricky. `try { Get-Content items.txt | Do-Something } catch {}` might not catch an error if `Do-Something` throws it inside a process block without terminating the pipeline.
    *   *Fix:* Use `$ErrorActionPreference = 'Stop'` at the top of the script.
*   **Native Commands (exe):** Standard `Try/Catch` does **not** catch errors from non-PowerShell executables (like `git.exe` or `kubectl`).
    *   *Fix:* Check `$LASTEXITCODE` after running an executable. `if ($LASTEXITCODE -ne 0) { throw "Command failed" }`.

## 6. Industry Context (Current Date)

*   **PowerShell 7+ Features:**
    *   **`Get-Error`**: A new cmdlet that dumps the full details of the last error object, far superior to inspecting `$Error[0]`.
    *   **Pipeline Chain Operators (`&&`, `||`)**: Run commands conditionally based on success/failure of the previous one.
        *   `Test-Path $file && Remove-Item $file` (Only remove if exists)
    *   **ConciseView**: PowerShell 7 defaults to a cleaner, colored error view.
*   **Pester Testing:** Modern production scripts use **Pester** (the testing framework) to verify error handling logic.
    *   Example: ` { Invoke-MyScript } | Should -Throw -ExpectedMessage "Critical Failure" `
*   **Cloud Logging:** The trend is moving away from local text files toward direct logging to cloud collectors (Azure Monitor, AWS CloudWatch) using custom modules or CLI agents.

## 7. References & Authority

*   **Official Docs:** [about_Try_Catch_Finally](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_try_catch_finally)
*   **Deep Dive:** [Kevin MarquetteΓÇÖs "Everything you wanted to know about exceptions"](https://powershellexplained.com/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/)
*   **Tooling:** [PoshLog](https://github.com/PoShLog/PoShLog) (C# based logger for PowerShell), [Pester](https://pester.dev/) (Testing framework).
