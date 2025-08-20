# ===========================
# O365 Mobile Devices Report - Non-Parallel
# ===========================

# Connect
Connect-ExchangeOnline

# Thresholds
$minIOS     = 16
$minAndroid = 13

function Get-EOLStatus {
    param ($deviceType, $osString)
    if (-not $osString) { return "Unknown" }
    if ($osString -match "\d+") { $ver = [int]$matches[0] }

    if ($deviceType -match "iPhone|iPad" -or ($deviceType -eq "Outlook" -and $osString -match "iOS")) {
        return if ($ver -lt $minIOS) { "Unsupported" } else { "Supported" }
    }
    elseif ($deviceType -match "Android" -or ($deviceType -eq "Outlook" -and $osString -match "Android")) {
        return if ($ver -lt $minAndroid) { "Unsupported" } else { "Supported" }
    }
    else { return "Check Manually" }
}

# 90-day cutoff
$cutoffDate = (Get-Date).AddDays(-90)

# Tenant name
$tenantName = (Get-OrganizationConfig).OrganisationName
if ([string]::IsNullOrWhiteSpace($tenantName)) { $tenantName = "UnknownTenant" }
$tenantName = $tenantName -replace '\s',''

# ---------------------------
# ActiveSync Devices
# ---------------------------
$allDevices = @()

$mobileDevices = Get-MobileDevice | Where-Object { $_.DeviceId -notmatch "§" }

foreach ($device in $mobileDevices) {
    try {
        $stats = Get-MobileDeviceStatistics -Identity $device.Identity -ErrorAction Stop

        if ($stats.LastSuccessSync -and $stats.LastSuccessSync -ge $cutoffDate) {
            $UPN = if ($device.UserPrincipalName) { $device.UserPrincipalName } else { $device.UserDisplayName }
            $EOLState = if ($device.DeviceOS -match "\d+") {
                            $ver = [int]$matches[0]
                            if ($device.DeviceType -match "iPhone|iPad") { if ($ver -lt $minIOS) {"Unsupported"} else {"Supported"} }
                            elseif ($device.DeviceType -match "Android") { if ($ver -lt $minAndroid) {"Unsupported"} else {"Supported"} }
                            else { "Check Manually" }
                        } else { "Unknown" }

            $allDevices += [PSCustomObject]@{
                UserPrincipalName = $UPN
                DisplayName       = $device.UserDisplayName
                DeviceID          = $device.DeviceId
                DeviceType        = $device.DeviceType
                DeviceModel       = $device.DeviceModel
                DeviceOS          = $device.DeviceOS
                ClientApp         = "ActiveSync"
                LastSyncTime      = $stats.LastSuccessSync
                FirstSyncTime     = $stats.FirstSyncTime
                DeviceFriendlyName= $stats.DeviceFriendlyName
                AccessState       = $device.DeviceAccessState
                DeviceUserAgent   = $stats.DeviceUserAgent
                EOLState          = $EOLState
            }
        }
    }
    catch {
        Write-Warning "Failed to get stats for device $($device.DeviceId)"
    }
}

# ---------------------------
# Export CSV
# ---------------------------
$exportFolder = "C:\AceIT"
if (-not (Test-Path $exportFolder)) { New-Item -ItemType Directory -Path $exportFolder | Out-Null }
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$exportPath = Join-Path $exportFolder "O365-AllMobileDevicesReport-$tenantName-$timestamp.csv"

$allDevices | Sort-Object LastSyncTime -Descending | Export-Csv $exportPath -NoTypeInformation -Encoding UTF8

Write-Host "? Unified report exported to $exportPath"
