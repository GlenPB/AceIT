<#
.SYNOPSIS
    Exchange On-Premises Log Cleanup (Full Purge)

.DESCRIPTION
    Removes ALL IIS and Exchange diagnostic/component logs regardless of age.
    Does not touch mailbox database transaction logs.

.NOTES
    Run as Administrator.
#>

Write-Host "Deleting ALL IIS and Exchange logs (no retention applied)...`n"

# IIS Logs
$IISLogPaths = @(
    "C:\inetpub\logs\LogFiles\W3SVC1",
    "C:\inetpub\logs\LogFiles\W3SVC2"
)

foreach ($Path in $IISLogPaths) {
    if (Test-Path $Path) {
        Get-ChildItem -Path $Path -File -Filter *.log |
            ForEach-Object {
                try {
                    Remove-Item $_.FullName -Force -ErrorAction Stop
                    Write-Host "Deleted $($_.FullName)"
                }
                catch {
                    Write-Host "Failed to delete $($_.FullName): $_"
                }
            }
        Write-Host "Completed IIS log cleanup for $Path"
    }
}

# Exchange Diagnostic / Component Logs
$ExchangeLogPath = "C:\Program Files\Microsoft\Exchange Server\V15\Logging"
if (Test-Path $ExchangeLogPath) {
    Get-ChildItem -Path $ExchangeLogPath -Recurse -File |
        Where-Object { $_.Extension -in ".log", ".blg", ".etl" } |
        ForEach-Object {
            try {
                Remove-Item $_.FullName -Force -ErrorAction Stop
                Write-Host "Deleted $($_.FullName)"
            }
            catch {
                Write-Host "Failed to delete $($_.FullName): $_"
            }
        }
    Write-Host "Completed Exchange log cleanup for $ExchangeLogPath"
}

Write-Host "`Full purge log cleanup complete."
