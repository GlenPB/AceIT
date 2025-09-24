<#
  dns-enumerate-clean.ps1
  Queries many DNS record types for a domain, against both system resolver and authoritative NS,
  then writes results to C:\aceit\PublicDNS-<domain>.csv with a user-friendly RecordData column.
  Blank responses are skipped.

  Usage:
    .\dns-enumerate-clean.ps1 -Domain example.com
#>

param(
    [Parameter(Mandatory=$true)][string]$Domain
)

# record types to query
$recordTypes = @("A","AAAA","CNAME","MX","NS","SOA","TXT","SRV","CAA","NAPTR","DS","DNSKEY","TLSA")

# sanitize domain for filename
$safeDomain = $Domain -replace '[^A-Za-z0-9\.-]', '_'

# output path (overwrite each run)
$outDir = "C:\aceit"
$csvPath = Join-Path $outDir ("PublicDNS-$safeDomain.csv")

if (-not (Test-Path -Path $outDir)) {
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null
}

Write-Host "Querying: $Domain"
Write-Host "Saving to: $csvPath"

function Query-Type {
    param($Name, $Type, $Server = $null)
    try {
        if ($Server) {
            return Resolve-DnsName -Name $Name -Type $Type -Server $Server -ErrorAction Stop
        } else {
            return Resolve-DnsName -Name $Name -Type $Type -ErrorAction Stop
        }
    } catch {
        return $null
    }
}

function Get-RecordData {
    param($r, $type)

    switch ($type) {
        "A"     { return $r.IPAddress }
        "AAAA"  { return $r.IPAddress }
        "MX"    { return "$($r.NameExchange) (Preference $($r.Preference))" }
        "NS"    { return $r.NameHost }
        "CNAME" { return $r.CName }
        "TXT"   { return ($r.Strings -join " ") }
        "SOA"   { return "$($r.PrimaryServer) / $($r.ResponsiblePerson)" }
        "CAA"   { return "$($r.Flags) $($r.Tag) $($r.Value)" }
        "SRV"   { return "$($r.Target):$($r.Port) (Priority $($r.Priority), Weight $($r.Weight))" }
        default {
            # fallback: return first non-empty property
            $props = $r.PSObject.Properties | Where-Object { $_.Value -and ($_.Name -notin @("Name","TTL","Type")) }
            if ($props) { return ($props | Select-Object -First 1).Value }
            else { return $null }
        }
    }
}

# find authoritative NS
$nsRecords = Query-Type -Name $Domain -Type "NS"
$authServers = @()
if ($nsRecords) {
    $authServers = $nsRecords | ForEach-Object { ($_.NameHost -as [string]).TrimEnd('.') } | Sort-Object -Unique
}

if ($authServers.Count -gt 0) {
    Write-Host "Authoritative nameservers: $($authServers -join ', ')"
} else {
    Write-Warning "No NS records found; using system resolver only."
}

$results = @()

# Query via system resolver
foreach ($type in $recordTypes) {
    $resp = Query-Type -Name $Domain -Type $type
    if ($resp) {
        foreach ($r in $resp) {
            $data = Get-RecordData $r $type
            if ($data) {
                $results += [PSCustomObject]@{
                    QueriedName   = $Domain
                    RecordType    = $type
                    AnswerName    = ($r.Name -replace '\.$','')
                    TTL           = $r.TTL
                    ServerQueried = "system-resolver"
                    RecordData    = $data
                }
            }
        }
    }
}

# Query via each authoritative NS
foreach ($ns in $authServers) {
    foreach ($type in $recordTypes) {
        $resp = Query-Type -Name $Domain -Type $type -Server $ns
        if ($resp) {
            foreach ($r in $resp) {
                $data = Get-RecordData $r $type
                if ($data) {
                    $results += [PSCustomObject]@{
                        QueriedName   = $Domain
                        RecordType    = $type
                        AnswerName    = ($r.Name -replace '\.$','')
                        TTL           = $r.TTL
                        ServerQueried = $ns
                        RecordData    = $data
                    }
                }
            }
        }
    }
}

# Export clean CSV
try {
    $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Force
    Write-Host "Wrote CSV summary to $csvPath"
} catch {
    Write-Error ("Failed to write CSV to {0}: {1}" -f $csvPath, $_.Exception.Message)
    exit 1
}

Write-Host "`nTotal records collected: $($results.Count)"
Write-Host "Done."
