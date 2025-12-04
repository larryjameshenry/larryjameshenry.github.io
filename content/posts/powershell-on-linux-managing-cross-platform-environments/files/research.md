Here is the comprehensive research report for **Article 4: PowerShell on Linux: Managing Cross-Platform Environments**.

## 1. Executive Summary & User Intent
*   **Core Definition:** PowerShell on Linux (specifically **PowerShell Core / PowerShell 7+**) is a cross-platform task automation and configuration management framework, consisting of a command-line shell and scripting language built on .NET Core. It allows administrators to apply the same object-oriented scripting skills used in Windows to Linux environments.
*   **User Intent:** The reader is a DevOps engineer or SysAdmin likely comfortable with Windows who needs to manage Linux servers. They are looking for *proof* that PowerShell is viable on Linux, specific *commands* to install it, and *patterns* to translate their Windows knowledge to Linux tasks (e.g., "How do I restart a service if `Restart-Service` doesn't work?").
*   **Relevance:** As hybrid cloud environments (Azure/AWS + Windows/Linux) become standard, the ability to write a single script that runs anywhere is a critical efficiency multiplier.

## 2. Key Technical Concepts & "All-Inclusive" Details
*   **Core Components:**
    *   **PowerShell Core (pwsh):** The binary executable on Linux. Unlike `powershell.exe` (Windows PowerShell 5.1), the Linux binary is simply `pwsh`.
    *   **.NET Core (Runtime):** The underlying framework. PowerShell 7+ bundles a self-contained .NET runtime, minimizing external dependencies.
    *   **PSRP over SSH:** PowerShell Remoting Protocol now runs over SSH (Secure Shell) on Linux, replacing the Windows-specific WinRM (Windows Remote Management).
*   **How it Works:** PowerShell on Linux interacts directly with the Linux kernel syscalls and standard streams (stdin/stdout/stderr). It treats text output from native Linux tools (like `ls` or `grep`) as strings, but internal PowerShell cmdlets (like `Get-Process`) output structured .NET objects.
*   **Key Terminology:**
    *   **Shebang (`#!/usr/bin/env pwsh`):** The first line in a script file that tells the Linux kernel which interpreter to use.
    *   **Case-Sensitivity:** Linux filesystems (ext4, xfs) are case-sensitive. `Get-ChildItem -Path /tmp/File.txt` is different from `/tmp/file.txt`.
    *   **Slash Direction:** Linux uses forward slashes (`/`) exclusively.
*   **Specific Metrics/Limits:**
    *   **Startup Time:** Generally slower than `bash` due to .NET runtime overhead (often ~200-500ms vs ~10ms).
    *   **Aliases:** Standard aliases (like `ls` -> `Get-ChildItem`) are often removed or modified on Linux to avoid conflict with native GNU tools.

## 3. Practical Implementation (The "Solid" Part)

### Installation (The "Standard Patterns")

**Ubuntu (via APT):**
```bash
# 1. Update the list of packages
sudo apt-get update

# 2. Install pre-requisite packages
sudo apt-get install -y wget apt-transport-https software-properties-common

# 3. Download the Microsoft repository GPG keys
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"

# 4. Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb

# 5. Update the list of packages after we added packages.microsoft.com
sudo apt-get update

# 6. Install PowerShell
sudo apt-get install -y powershell

# 7. Start PowerShell
pwsh
```

**RHEL / CentOS (via DNF/YUM):**
```bash
# 1. Register the Microsoft RedHat repository
sudo curl -o /etc/yum.repos.d/microsoft.repo https://packages.microsoft.com/config/rhel/8/prod.repo

# 2. Install PowerShell
sudo dnf install -y powershell

# 3. Start PowerShell
pwsh
```

### Managing Processes (Native Cmdlets Work)
PowerShell translates Linux process info into .NET objects automatically.
```powershell
# Get top 5 processes by memory usage
Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5

# Stop a specific process by name
Stop-Process -Name "nginx" -Force
```

### Managing Services (The "Hybrid" Approach)
Native cmdlets like `Get-Service` often rely on specific providers that may not map perfectly to `systemd`. The standard pattern is invoking `systemctl` directly within PowerShell.

```powershell
# Check status (Invoking native binary)
systemctl status nginx

# Managing services via PowerShell wrapper (Best practice for automation)
$service = "nginx"
if (systemctl is-active --quiet $service) {
    Write-Host "$service is running." -ForegroundColor Green
} else {
    Write-Host "Starting $service..."
    sudo systemctl start $service
}
```

### Remoting over SSH (Configuration)
To enable a Linux server to *receive* PowerShell remoting commands, edit `/etc/ssh/sshd_config`:

```text
# Add this line to sshd_config
Subsystem powershell /usr/bin/pwsh -sshs -NoLogo
```
*Restart sshd (`sudo systemctl restart sshd`), then from a Windows machine:*
```powershell
Enter-PSSession -HostName "192.168.1.50" -UserName "admin" -SSHTransport
```

## 4. Best Practices vs. Anti-Patterns

### Do This (Best Practices)
*   **Use `Join-Path`:** Never hardcode slashes.
    *   *Good:* `Join-Path $PSScriptRoot "data" "config.json"`
    *   *Bad:* `"$PSScriptRoot/data/config.json"`
*   **Use `$IsLinux` / `$IsWindows`:** Built-in boolean variables to branch logic.
    ```powershell
    if ($IsLinux) { $Path = "/var/log" } else { $Path = "C:\Logs" }
    ```
*   **Shebang headers:** Always add `#!/usr/bin/env pwsh` at the top of `.ps1` files intended to run as executables on Linux.
*   **Use `[Environment]::NewLine`:** Instead of `` `r`n `` (Windows style CRLF), which breaks some Linux configs requiring LF.

### Don't Do This (Anti-Patterns)
*   **Reliance on Aliases:** Do not use `dir`, `ls`, `cp`, or `mv` in scripts. On Linux `ls` runs the native GNU `ls` (returning strings), whereas `dir` is an alias for `Get-ChildItem` (returning objects). This confusion causes bugs. **Always use full cmdlet names (`Get-ChildItem`).**
*   **Assume WMI/CIM:** `Get-WmiObject` and `Get-CimInstance` are largely Windows-exclusive. They do not exist on Linux.

## 5. Edge Cases & Troubleshooting
*   **Case Sensitivity Errors:** A script calling `Import-Module ./MyModule` will fail if the folder is actually named `mymodule` on Linux (but works on Windows).
    *   *Fix:* Audit filenames rigorously or use `Get-ChildItem` to discover the exact casing at runtime.
*   **Path Separators:** Windows accepts forward slashes (`/`) in many APIs, but Linux *never* accepts backslashes (`\`) as separators (it treats them as escape characters).
*   **Sudo/Permissions:** Running `pwsh` does not grant root. You must run `sudo pwsh` or standard `sudo` commands inside the shell.
    *   *Edge Case:* `Start-Process -Verb RunAs` (the standard Windows "Run as Administrator" method) **does not work** on Linux. You must handle privilege elevation externally (e.g., via `sudo` in the invocation).

## 6. Industry Context (As of Late 2025)
*   **Trends:** There is a massive shift toward **"PSResourceGet"** (the successor to PowerShellGet) for managing modules cross-platform.
*   **Alternatives:**
    *   **Python (Boto3/Ansible):** Dominant in pure Linux environments. PowerShell is preferred in "Mixed/Hybrid" shops where the team already knows PowerShell.
    *   **Bash:** The native standard. Lacks object-oriented data passing, making complex logic (parsing JSON/XML) harder than in PowerShell.

## 7. References & Authority
*   **Official Docs:** [Microsoft: Installing PowerShell on Linux](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux)
*   **SSH Remoting:** [PowerShell Remoting over SSH](https://learn.microsoft.com/en-us/powershell/scripting/learn/remoting/ssh-remoting-in-powershell-core)
*   **Further Reading:** "PowerShell for Sysadmins" by Adam Bertram (validates cross-platform workflow concepts).
