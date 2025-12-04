---
slug: "testing-infrastructure-with-pester-beyond-unit-tests"
title: "Testing Infrastructure with Pester: Beyond Unit Tests"
date: 2025-12-03T22:37:53-05:00
draft: true
series: ["powershell-automation-for-devops"]
weight: 3
image: images/featured-image.jpg
---

Manual verification of infrastructure is a bottleneck. You spend hours building a server, deploying an application, and then manually checking services, ports, and URLs. If you miss one check, the application fails in production.

Automation solves this, but many engineers stop at "Infrastructure as Code" (IaC). IaC builds the server, but it doesn't guarantee the application is running correctly *inside* it.

Pester, the standard testing framework for PowerShell, handles more than just unit testing scripts. It validates operational state. You can write tests that confirm a service is running, a port is open, or an API endpoint returns a 200 OK. This article explains how to turn manual checklists into automated Pester tests that run in seconds.

## Introduction to Pester for Infrastructure Testing

Most developers know Pester for unit testingΓÇövalidating logic by mocking dependencies. Infrastructure testing (often called Operation Validation) is different. You don't mock the environment; you query the live environment to assert its state.

In this context, Pester acts as a compliance engine. It runs commands against a target system and compares the actual result with the expected result. If a web server must listen on port 443, Pester attempts a connection. If the connection succeeds, the test passes. If it fails, Pester reports the error.

This approach shifts verification from "I think it works because the script finished" to "I know it works because I tested the final state."

## Setting Up Pester for Infrastructure Validation

To start, you need the Pester module installed. Pester v5 is the current standard and introduces important structural changes over v4, specifically in how it discovers and runs tests.

Install the module from the PowerShell Gallery:

```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

Organize your infrastructure tests separately from your unit tests. A common pattern is to create a `tests` directory with a dedicated `infrastructure` folder:

```text
.
Γö£ΓöÇΓöÇ src/
Γö£ΓöÇΓöÇ tests/
Γöé   Γö£ΓöÇΓöÇ unit/
Γöé   ΓööΓöÇΓöÇ infrastructure/
Γöé       Γö£ΓöÇΓöÇ active-directory.tests.ps1
Γöé       ΓööΓöÇΓöÇ web-server.tests.ps1
```

This separation matters because infrastructure tests often require specific permissions or network access that unit tests do not.

## Writing Pester Tests for Infrastructure State

Pester v5 uses `Describe` and `It` blocks to structure tests. For infrastructure, use `BeforeAll` to gather data (the "Arrange" and "Act" phases) and `It` to validate the data (the "Assert" phase).

### Scenario 1: Verifying Service Status

Checking if a critical service is running is the most basic infrastructure test.

```powershell
Describe "Web Server Service Health" {
    BeforeAll {
        # Act: Get the service object once
        $Service = Get-Service -Name "w3svc" -ErrorAction SilentlyContinue
    }

    It "The World Wide Web Publishing Service should be installed" {
        $Service | Should -Not -BeNullOrEmpty
    }

    It "The service should be in the 'Running' state" {
        $Service.Status | Should -Be "Running"
    }

    It "The service should be set to 'Automatic' startup" {
        $Service.StartType | Should -Be "Automatic"
    }
}
```

### Scenario 2: Testing Network Connectivity

Services might run, but firewalls can block access. Use `Test-NetConnection` to verify port availability.

```powershell
Describe "Database Connectivity" {
    BeforeAll {
        # Arrange: Define the target
        $Server = "db-prod-01"
        $Port = 1433
        
        # Act: Test the connection
        $Connection = Test-NetConnection -ComputerName $Server -Port $Port
    }

    It "Should be able to reach port $Port on $Server" {
        $Connection.TcpTestSucceeded | Should -BeTrue
    }
}
```

### Scenario 3: Validating HTTP Endpoints

For web applications, the ultimate test is an HTTP request. This confirms the web server, app code, and database are all communicating.

```powershell
Describe "Public Website Availability" {
    BeforeAll {
        $Uri = "https://myapp.internal/health"
        try {
            $Response = Invoke-RestMethod -Uri $Uri -Method Head -ErrorAction Stop
            $StatusCode = 200 # Invoke-RestMethod returns data, not status, on success usually, 
                              # but for HEAD or checking availability, we assume success = 200
        }
        catch {
            $StatusCode = $_.Exception.Response.StatusCode.value__
        }
    }

    It "The health endpoint should return HTTP 200" {
        $StatusCode | Should -Be 200
    }
}
```

> **Note:** `Invoke-RestMethod` throws a terminating error for HTTP 4xx/5xx codes. Wrap it in `try/catch` to assert on the status code rather than crashing the test.

## Differentiating Code Unit Tests from Infrastructure Tests

Confusing unit tests with infrastructure tests leads to slow, brittle pipelines. Understand the differences to place them correctly in your workflow.

| Feature | Unit Tests | Infrastructure Tests |
| :--- | :--- | :--- |
| **Goal** | Verify logic correctness | Verify system state |
| **Dependencies** | Mocked (Fake) | Live (Real) |
| **Speed** | Milliseconds | Seconds to Minutes |
| **Environment** | Build Server | Target Environment |
| **Failure Means** | Bug in code logic | Deployment failure or outage |

Unit tests run during the **build** phase. They prove your script *logic* handles parameters correctly. Infrastructure tests run during the **deploy** phase. They prove your script *actually configured* the server correctly.

## Integrating Pester Tests into CI/CD Pipelines

Infrastructure tests serve as "Quality Gates" in your release pipeline. If the tests fail, the deployment should be marked as failed, triggering a rollback or alert.

Most CI/CD platforms (Azure DevOps, GitHub Actions, GitLab CI) can parse Pester results using NUnit XML format.

Run Pester with `Passthru` to exit with a failure code if tests fail, and `OutputFormat` to generate the report.

```powershell
$Config = [PesterConfiguration]@{
    Run = @{
        Path = "./tests/infrastructure"
        PassThru = $true
    }
    TestResult = @{
        Enabled = $true
        OutputFormat = "NUnitXml"
        OutputPath = "./test-results.xml"
    }
}

Invoke-Pester -Configuration $Config
```

In your pipeline YAML, publish `test-results.xml` to see a visual report of which infrastructure checks passed or failed.

## Best Practices for Reliable Infrastructure Tests

1.  **Use Discovery/Run Phases Correctly:** Pester v5 separates file discovery from execution. Do not put expensive code (like API calls) at the top level of your script. Put them inside `BeforeAll` blocks.
2.  **Keep Tests Read-Only:** Infrastructure tests should observe, not modify. If your test creates a file to check permissions, ensure you clean it up in an `AfterAll` block.
3.  **Avoid Hardcoded Secrets:** Never put passwords in your tests. Use environment variables or a secret management vault to retrieve credentials during the `BeforeAll` phase.
4.  **Test from the Outside In:** Run tests from a separate "jump box" or agent, not just localhost. This validates network paths, firewalls, and permissions exactly as a user would experience them.

## Troubleshooting Common Issues

**Tests fail with "Access Denied":**
Infrastructure tests often need administrative privileges. Ensure the CI/CD agent runs with appropriate credentials, or use `Invoke-Command` to execute the test block on the target node using a privileged session.

**Tests are slow or time out:**
Network checks like `Test-NetConnection` have long default timeouts. Use parameters like `-Timeout 1000` (milliseconds) in your custom logic if available, or run tests in parallel using Pester's `-Container` isolation if supported by your resources.

**Flaky tests due to service startup time:**
Services take time to start after a deployment. If a test fails immediately, add a retry loop or a `Start-Sleep` in your pipeline *before* triggering the Pester suite.

## Conclusion

Automating infrastructure validation with Pester moves you from hope-based deployments to proof-based deployments.

**Key Takeaways:**
1.  **Validate Reality:** Don't trust your deployment script; verify the actual state of the server.
2.  **Separate Concerns:** Keep unit tests (logic) and infrastructure tests (state) in distinct folders and pipeline stages.
3.  **Fail Fast:** Run Pester immediately after deployment to catch issues before users do.
4.  **Report Clearly:** Use NUnit XML output to visualize health in your CI/CD dashboard.
5.  **Start Small:** Begin by testing the three "golden signals": Service Status, Port Open, URL Accessible.

By implementing these tests, you define exactly what "done" looks like for your infrastructure, preventing configuration drift and silent failures.
