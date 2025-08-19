 # -------------------------------
# Step 0: Install required modules if missing
# -------------------------------
$modules = @("Microsoft.Graph", "ExchangeOnlineManagement")
foreach ($mod in $modules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Install-Module $mod -Scope CurrentUser -Force
    }
}

# -------------------------------
# Step 1: Connect to Microsoft Graph
# -------------------------------
Connect-MgGraph -Scopes "User.Read.All","Directory.Read.All"

# -------------------------------
# Step 2: Fetch SKU friendly names
# -------------------------------
$licenseCsvURL = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'
$skuFriendly = @{}
(Invoke-RestMethod -Uri $licenseCsvURL | ConvertFrom-Csv) | ForEach-Object {
    $skuFriendly[$_.String_Id] = $_.Product_Display_Name
}

# Extra SKUs
$extraSkus = @{
    "O365_BUSINESS_BASIC"      = "Microsoft 365 Business Basic"
    "O365_BUSINESS_STANDARD"   = "Microsoft 365 Business Standard"
    "PROJECT_ESSENTIALS"       = "Project Plan 1"
    "PROJECT_PLAN3"            = "Project Plan 3"
    "PROJECT_PLAN5"            = "Project Plan 5"
    "EXCHANGE_S_ENTERPRISE"    = "Exchange Online Plan 2"
    "EXCHANGE_S_STANDARD"      = "Exchange Online Plan 1"
}
$skuFriendly += $extraSkus

# -------------------------------
# Step 3: Get subscribed SKUs via REST
# -------------------------------
$skus = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/subscribedSkus"
$skuMap = @{}
foreach ($sku in $skus.value) {
    $skuMap[$sku.skuId] = $skuFriendly[$sku.skuPartNumber] ?? $sku.skuPartNumber
}

# -------------------------------
# Step 4: Fetch all licensed users
# -------------------------------
$licensedUsers = Get-MgUser -All -Property DisplayName,UserPrincipalName,AssignedLicenses |
    Where-Object { $_.AssignedLicenses.Count -gt 0 } |
    Select-Object DisplayName, UserPrincipalName,
        @{Name="Licenses";Expression={ ($_.AssignedLicenses | ForEach-Object { $skuMap[$_.SkuId] ?? $_.SkuId }) -join ", " }}

# -------------------------------
# Step 5: Connect to Exchange Online
# -------------------------------
Connect-ExchangeOnline -ShowProgress $true

# -------------------------------
# Step 6: Get mailbox size per user and flag large mailboxes (>50 GB)
# -------------------------------
$licensedUsersWithMailbox = $licensedUsers | ForEach-Object {
    $mbxStats = Get-EXOMailboxStatistics -Identity $_.UserPrincipalName -ErrorAction SilentlyContinue

    $sizeStr = "N/A"
    $sizeGB = 0
    if ($mbxStats -and $mbxStats.TotalItemSize) {
        # Convert to numeric GB
        if ($mbxStats.TotalItemSize -match "([\d\.]+)\sGB") {
            $sizeGB = [double]$matches[1]
            $sizeStr = "$sizeGB GB"
        } elseif ($mbxStats.TotalItemSize -match "([\d\.]+)\sMB") {
            $sizeGB = [double]$matches[1] / 1024
            $sizeStr = "{0:N2} GB" -f $sizeGB
        } elseif ($mbxStats.TotalItemSize -match "([\d\.]+)\sKB") {
            $sizeGB = [double]$matches[1] / 1024 / 1024
            $sizeStr = "{0:N2} GB" -f $sizeGB
        }
    }

    [PSCustomObject]@{
        DisplayName       = $_.DisplayName
        UserPrincipalName = $_.UserPrincipalName
        Licenses          = $_.Licenses
        MailboxSize       = $sizeStr
        LargeMailbox      = if ($sizeGB -gt 50) { "Yes" } else { "No" }
    }
}

# -------------------------------
# Step 7: Split licenses into columns
# -------------------------------
$allLicenses = ($licensedUsersWithMailbox | ForEach-Object { $_.Licenses -split ', ' }) | Sort-Object -Unique

$report = $licensedUsersWithMailbox | ForEach-Object {
    $obj = [ordered]@{
        DisplayName       = $_.DisplayName
        UserPrincipalName = $_.UserPrincipalName
        MailboxSize       = $_.MailboxSize
        LargeMailbox      = $_.LargeMailbox
    }

    foreach ($lic in $allLicenses) {
        $obj[$lic] = if ($_.Licenses -split ', ' -contains $lic) { 1 } else { 0 }
    }

    [PSCustomObject]$obj
}

# -------------------------------
# Step 8: Add totals row
# -------------------------------
$totals = [ordered]@{
    DisplayName       = "TOTAL"
    UserPrincipalName = ""
    MailboxSize       = ""
    LargeMailbox      = ""
}
foreach ($lic in $allLicenses) {
    $totals[$lic] = ($report | Measure-Object -Property $lic -Sum).Sum
}
$report += [PSCustomObject]$totals

# -------------------------------
# Step 9: Reorder license columns by total count
# -------------------------------
$totalsRow = $report | Where-Object { $_.DisplayName -eq "TOTAL" }
$licenseColumns = ($allLicenses | Sort-Object { -1 * $totalsRow.$_ })
$finalColumnOrder = @("DisplayName","UserPrincipalName","MailboxSize","LargeMailbox") + $licenseColumns
$reportOrdered = $report | Select-Object $finalColumnOrder

# -------------------------------
# Step 10: Export CSV to C:\AceIT
# -------------------------------
$exportFolder = "C:\AceIT"
if (-not (Test-Path -Path $exportFolder)) {
    New-Item -Path $exportFolder -ItemType Directory -Force | Out-Null
}

$exportPath = Join-Path -Path $exportFolder -ChildPath "LicensedUsers_WithMailbox_ByLicense_Sorted.csv"
$reportOrdered | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

# -------------------------------
# Step 11: Confirm export
# -------------------------------
Write-Host "`n✅ Export complete!" -ForegroundColor Green
Write-Host "CSV file saved to: $exportPath" -ForegroundColor Cyan
