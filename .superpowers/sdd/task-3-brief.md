## Global Constraints

- Must read configuration from `config.psd1` using `Import-PowerShellDataFile`.
- Do not crash on offline servers; record their error messages and exit with code 1.
- Exit code 2 for fatal configuration/SMTP errors (do not use `Write-Error` if you want to control the exit code).
- Target `Microsoft.Data.SqlClient` with `Encrypt=True;TrustServerCertificate=True`.



### Task 3: Job Exceptions T-SQL
