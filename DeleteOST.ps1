# Run as Administrator
Get-ChildItem -Path "C:\Users" -Directory | ForEach-Object {
    $ostPath = Join-Path $_.FullName "AppData\Local\Microsoft\Outlook"
    if (Test-Path $ostPath) {
        Get-ChildItem -Path $ostPath -Filter *.ost -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                try {
                    $stream = [System.IO.File]::Open($_.FullName, 'Open', 'ReadWrite', 'None')
                    $stream.Close()
                    Remove-Item $_.FullName -Force
                    Write-Output "Deleted: $($_.FullName)"
                } catch {
                    Write-Output "In use, skipped: $($_.FullName)"
                }
            }
    }
}
