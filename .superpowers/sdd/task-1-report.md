# Task 1 Report: Configuration & Parameterization

## What Was Implemented
- Created [config.example.psd1](file:///C:/Users/rudi.bruchez.ext/OneDrive%20-%20NEOEN/Sources/tsql-scripts/powershell/daily-check/config.example.psd1) as a template for database check parameters, email settings, lookback thresholds, and connection encryption options.
- Refactored [daily-check.ps1](file:///C:/Users/rudi.bruchez.ext/OneDrive%20-%20NEOEN/Sources/tsql-scripts/powershell/daily-check/daily-check.ps1) with a parameterized scaffold accepting `-Instance` and `-OutputPath`, and validating the presence and schema of `config.psd1`. Missing configuration or instance files now cleanly exit with code 2 and user-facing error messages to `$Host.UI.WriteErrorLine`.
- Updated [.gitignore](file:///C:/Users/rudi.bruchez.ext/OneDrive%20-%20NEOEN/Sources/tsql-scripts/.gitignore) to ignore `config.psd1`.

## TDD Evidence

### RED Phase
- **Command:**
  ```powershell
  pwsh -c "if (Test-Path config.psd1) { Remove-Item config.psd1 }; .\daily-check.ps1; if (`$LASTEXITCODE -ne 2) { throw 'Expected exit 2, got: ' + `$LASTEXITCODE }"
  ```
- **Output:**
  ```text
  Set-Location: Cannot find drive. A drive with the name 'E' does not exist.
  Get-Content: Cannot find path '...\config\instances.txt' because it does not exist.
  MethodInvocationException: Failure sending mail.
  Exception: Expected exit 2, got: 
  ```
- **Why it failed as expected:** The legacy script lacked `config.psd1` validation, relied on hardcoded `E:\` paths, and threw uncaught exceptions instead of exiting with exit code 2 when configuration was absent.

### GREEN Phase
- **Command:**
  ```powershell
  pwsh -c "
  # Test 1: Missing config.psd1
  if (Test-Path config.psd1) { Remove-Item config.psd1 }
  `$LASTEXITCODE = 0
  .\daily-check.ps1
  if (`$LASTEXITCODE -ne 2) { throw 'Test 1 Failed' }

  # Test 2: Missing required key
  Set-Content config.psd1 '@{ EmailFrom = ''test@example.com'' }'
  `$LASTEXITCODE = 0
  .\daily-check.ps1 -Instance localhost
  if (`$LASTEXITCODE -ne 2) { throw 'Test 2 Failed' }

  # Test 3: Missing instances file without -Instance
  Copy-Item config.example.psd1 config.psd1
  `$LASTEXITCODE = 0
  .\daily-check.ps1
  if (`$LASTEXITCODE -ne 2) { throw 'Test 3 Failed' }

  # Test 4: Valid config with -Instance
  `$LASTEXITCODE = 0
  .\daily-check.ps1 -Instance localhost
  if (`$LASTEXITCODE -ne 0) { throw 'Test 4 Failed' }

  Remove-Item config.psd1
  Write-Host 'All 4/4 verification tests passed successfully.'
  "
  ```
- **Output:**
  ```text
  Configuration file missing: C:\Users\rudi.bruchez.ext\OneDrive - NEOEN\Sources\tsql-scripts\powershell\daily-check\config.psd1
  Missing config key: EmailTo
  Instances file missing: config\instances.txt
  All 4/4 verification tests passed successfully.
  ```

## Files Changed
- [powershell/daily-check/config.example.psd1](file:///C:/Users/rudi.bruchez.ext/OneDrive%20-%20NEOEN/Sources/tsql-scripts/powershell/daily-check/config.example.psd1) (Created)
- [powershell/daily-check/daily-check.ps1](file:///C:/Users/rudi.bruchez.ext/OneDrive%20-%20NEOEN/Sources/tsql-scripts/powershell/daily-check/daily-check.ps1) (Scaffold updated)
- [.gitignore](file:///C:/Users/rudi.bruchez.ext/OneDrive%20-%20NEOEN/Sources/tsql-scripts/.gitignore) (Modified)

## Commits
- `f0c5939`: feat: add config.psd1 scaffold and parameters

## Self-Review Findings
- **Completeness:** Implemented all requirements for Task 1: `config.example.psd1` creation, `daily-check.ps1` parameterization & config parsing with error code 2 handling, and `.gitignore` update.
- **Quality:** Code follows PowerShell standard error handling and script structure without clutter.
- **Discipline:** No extraneous files modified or over-engineered logic outside Task 1.

## Issues & Concerns
None.
