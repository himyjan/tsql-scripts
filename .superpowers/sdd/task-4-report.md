# Task 4 Report: Main Script Assembly & Offline Handling

## 1. What was Implemented
- Assembled the complete main script in powershell/daily-check/daily-check.ps1:
  - Configuration parsing and validation with fallback defaults (LookbackHours, BaselineDays, RetentionDays, SmtpPort).
  - Strict fatal configuration error handling with exit code 2 when config file, required config keys, instances file, or sql/job-exceptions.sql are missing or invalid.
  - Parameter substitution for sql/job-exceptions.sql with robust regex patterns handling arbitrary whitespace.
  - Multi-instance query loop executing engine edition probe, database health query, and SQL Agent job exceptions query (skipping jobs query on Azure SQL Database editions 5, 6, 9, 11, 12).
  - Graceful per-instance exception handling capturing error messages into $unreachable and logging error lines without terminating the overall script.
  - HTML report assembly aggregating "Instances with Errors", "Database Health", and "Job Exceptions" sections with UTF-8 metadata and CSS styling (.row-error for Failed/Canceled jobs, .row-warn for duration anomalies).
  - Subject prefix determination ([ERRORS], [WARN], or default) based on unreachable instance count and job outcome statuses.
  - Output routing: writing directly to -OutputPath (for dry-run/testing) or logging to $cfg.LogPath and dispatching via Send-DailyCheckReport with log file retention cleanup based on RetentionDays.
  - Exit code contract: 0 for all instances OK and no job failures, 1 when errors or job failures occurred, 2 for fatal configuration/SMTP errors.

## 2. Testing & Verification Results
Full 8-case automated test suite executed and passed:
- **Test 1:** Missing config.psd1 correctly exits with code 2.
- **Test 2:** Missing required configuration key correctly exits with code 2.
- **Test 3:** Missing instances file (without -Instance) correctly exits with code 2.
- **Test 4:** Offline/unreachable server with -Instance and -OutputPath does not crash, logs error message, outputs HTML report containing <h2>Instances with Errors</h2> and <meta charset="utf-8">, and exits with code 1.
- **Test 5 (Scenario A):** Healthy database and no job anomalies generates complete HTML tables with "No job anomalies detected.", subject SQL Server Daily Check, and exits with code 0.
- **Test 6 (Scenario B):** Job failures (Failed, Canceled) generate HTML with .row-error CSS rows, subject prefix [ERRORS], and exits with code 1.
- **Test 7 (Scenario C):** Job duration anomalies (Succeeded) generate HTML with .row-warn CSS rows, subject prefix [WARN], and exits with code 0.
- **Test 8 (Scenario D):** Azure SQL Database (EngineEdition = 5) queries database health without error and skips SQL Agent jobs query, exiting with code 0.
- **Retention Test:** Verified HTML log files older than RetentionDays are deleted while current files are preserved.

## 3. Files Changed
- powershell/daily-check/daily-check.ps1 (modified, committed)

## 4. Self-Review Findings
- **Completeness:** All plan requirements, global constraints, and design specs implemented.
- **Error Handling:** Non-terminating host error messages used alongside controlled exit codes (1 for unreachable/job failures, 2 for fatal errors).
- **Encoding & Layout:** HTML head includes <meta charset="utf-8"> and Set-Content explicitly specifies -Encoding UTF8.
- **Quality & Discipline:** Clean code structure, consistent variables, proper resource disposal across helper functions.

## 5. Concerns / Notes
None. All tests pass cleanly with 0 defects.
