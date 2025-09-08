Import-Module ActiveDirectory

# Set threshold
$DaysInactive = 90
$Time = (Get-Date).AddDays(-$DaysInactive)

# Log file location
$LogFile = "C:\AceIT\AD\DisabledAccounts.csv"

# Ensure folder exists
$LogFolder = Split-Path $LogFile
if (-not (Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder -Force
}

# If log file doesn't exist, create it with headers
if (-not (Test-Path $LogFile)) {
    "Name,SamAccountName,LastLogonDate,DisabledDate" | Out-File -FilePath $LogFile -Encoding UTF8
}

# List of groups to exclude
$ExcludedGroups = @(
    "Domain Admins"
    "Enterprise Admins"
    "Schema Admins"
    "Administrators"
    # Add any other groups you want to exclude
)

# Get distinguished names of existing groups
$ExcludedGroupDNs = @()
foreach ($grp in $ExcludedGroups) {
    $adGroup = Get-ADGroup $grp -ErrorAction SilentlyContinue
    if ($adGroup) { $ExcludedGroupDNs += $adGroup.DistinguishedName }
}

# Find inactive users
Get-ADUser -Filter {LastLogonDate -lt $Time -and Enabled -eq $true} -Properties LastLogonDate |
ForEach-Object {
    $userGroups = (Get-ADPrincipalGroupMembership $_ | Select-Object -ExpandProperty DistinguishedName)
    
    # Skip user if member of any excluded group
    if ($userGroups | Where-Object { $ExcludedGroupDNs -contains $_ }) {
        Write-Output "Skipping account (excluded group): $($_.SamAccountName)"
        return
    }

    # Disable the account
    Disable-ADAccount -Identity $_.DistinguishedName
    $DisabledDate = Get-Date

    # Output to console
    Write-Output "Disabled account: $($_.SamAccountName) - Last logon: $($_.LastLogonDate)"

    # Log to CSV
    "$($_.Name),$($_.SamAccountName),$($_.LastLogonDate),$DisabledDate" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}
