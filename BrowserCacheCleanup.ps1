Write-Host -ForegroundColor Yellow "#######################################################"
""
Write-Host -ForegroundColor Green "Modernized PowerShell commands to delete cache & cookies in Firefox, Chrome & Edge"
Write-Host -ForegroundColor Green "Updated: September 2025"
Write-Host -ForegroundColor Green "VERSION: 3"
""
Write-Host -ForegroundColor Yellow "#######################################################"
""

#########################
"-------------------"
Write-Host -ForegroundColor Green "SECTION 1: Getting the list of users"
"-------------------"
Write-Host -ForegroundColor Yellow "Exporting the list of users to c:\users\$env:USERNAME\users.csv"
dir C:\Users | Select Name | Export-Csv -Path C:\Users\$env:USERNAME\users.csv -NoTypeInformation
$list = Test-Path C:\Users\$env:USERNAME\users.csv
""

#########################
"-------------------"
Write-Host -ForegroundColor Green "SECTION 2: Beginning Script..."
"-------------------"
if ($list) {
    # ------------------------------------
    # Clear Mozilla Firefox
    # ------------------------------------
    Write-Host -ForegroundColor Green "SECTION 3: Clearing Mozilla Firefox Caches"
    Write-Host -ForegroundColor Yellow "Clearing Firefox caches"
    Write-Host -ForegroundColor Cyan

    Import-CSV -Path C:\Users\$env:USERNAME\users.csv -Header Name | ForEach-Object {
        $ffPath = "C:\Users\$($_.Name)\AppData\Local\Mozilla\Firefox\Profiles"
        if (Test-Path $ffPath) {
            Get-ChildItem $ffPath -Directory | ForEach-Object {
                Remove-Item "$($_.FullName)\cache2\entries\*" -Recurse -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\cookies.sqlite" -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\webappsstore.sqlite" -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\chromeappsstore.sqlite" -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\thumbnails\*" -Recurse -Force -EA SilentlyContinue -Verbose
            }
        }
    }
    Write-Host -ForegroundColor Yellow "Done..."
    ""

    # ------------------------------------
    # Clear Google Chrome
    # ------------------------------------
    Write-Host -ForegroundColor Green "SECTION 4: Clearing Google Chrome Caches"
    Write-Host -ForegroundColor Yellow "Clearing Chrome caches"
    Write-Host -ForegroundColor Cyan

    Import-CSV -Path C:\Users\$env:USERNAME\users.csv -Header Name | ForEach-Object {
        $chromeBase = "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data"
        if (Test-Path $chromeBase) {
            Get-ChildItem $chromeBase -Directory | ForEach-Object {
                Remove-Item "$($_.FullName)\Cache\*" -Recurse -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\Cache2\entries\*" -Recurse -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\Cookies" -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\Cookies-Journal" -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\Media Cache" -Recurse -Force -EA SilentlyContinue -Verbose
            }
        }
    }
    Write-Host -ForegroundColor Yellow "Done..."
    ""

    # ------------------------------------
    # Clear Microsoft Edge
    # ------------------------------------
    Write-Host -ForegroundColor Green "SECTION 5: Clearing Microsoft Edge Caches"
    Write-Host -ForegroundColor Yellow "Clearing Edge caches"
    Write-Host -ForegroundColor Cyan

    Import-CSV -Path C:\Users\$env:USERNAME\users.csv -Header Name | ForEach-Object {
        $edgeBase = "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data"
        if (Test-Path $edgeBase) {
            Get-ChildItem $edgeBase -Directory | ForEach-Object {
                Remove-Item "$($_.FullName)\Cache\*" -Recurse -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\Cache2\entries\*" -Recurse -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\Cookies" -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\Cookies-Journal" -Force -EA SilentlyContinue -Verbose
                Remove-Item "$($_.FullName)\Media Cache" -Recurse -Force -EA SilentlyContinue -Verbose
            }
        }
    }
    Write-Host -ForegroundColor Yellow "Done..."
    ""

    # ------------------------------------
    # Clear Windows Temp + Recycle Bin
    # ------------------------------------
    Write-Host -ForegroundColor Green "SECTION 6: Clearing Temp & Recycle Bin"
    Write-Host -ForegroundColor Cyan

    Import-CSV -Path C:\Users\$env:USERNAME\users.csv -Header Name | ForEach-Object {
        Remove-Item "C:\Users\$($_.Name)\AppData\Local\Temp\*" -Recurse -Force -EA SilentlyContinue -Verbose
    }
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue -Verbose
    Remove-Item "C:\$Recycle.Bin\*" -Recurse -Force -EA SilentlyContinue -Verbose

    Write-Host -ForegroundColor Yellow "Done..."
    ""
    Write-Host -ForegroundColor Green "All Tasks Done!"
} else {
    Write-Host -ForegroundColor Yellow "Session Cancelled"
    Exit
}
