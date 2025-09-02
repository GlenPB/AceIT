# Define output CSV path
$outputCsv = "C:\temp\FolderRedirectionReport.csv"

# Simple logging function
function Log-Message {
    param([string]$msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$time] $msg"
}

Log-Message "Starting folder redirection check..."

try {
    # Get interactive logged-in user
    $userInfo = Get-WmiObject -Class Win32_ComputerSystem
    $loggedInUser = $userInfo.UserName

    if (-not $loggedInUser) {
        throw "No user currently logged in."
    }

    $domain, $username = $loggedInUser -split '\\'

    # Get the user's SID
    $userAccount = Get-WmiObject Win32_UserAccount | Where-Object {
        $_.Name -eq $username -and $_.Domain -eq $domain
    }

    if (-not $userAccount) {
        throw "Could not find SID for user $loggedInUser"
    }

    $sid = $userAccount.SID

    # Registry path to User Shell Folders
    $regPath = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

    if (-not (Test-Path $regPath)) {
        throw "User Shell Folders key not found for SID $sid"
    }

    # Get folder redirection info
    $folders = Get-ItemProperty -Path $regPath
    $results = $folders.PSObject.Properties | ForEach-Object {
        [PSCustomObject]@{
            Folder     = $_.Name
            Path       = $_.Value
            Redirected = ($_.Value -like '\\*')
        }
    }

    # Display nicely in console
    $results | Format-Table -AutoSize

    # Export to CSV
    $results | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8

    Log-Message "Folder redirection data exported to $outputCsv"

} catch {
    Log-Message "ERROR: $_"
}

Log-Message "Finished folder redirection check."