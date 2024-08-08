# Set the reboot delay in the variable $Reboot_Delay
# By default it's 5 days, meaning is the device has not rebooted since 5 days or more a warning will be displayed
$Reboot_Delay = 14


	
$Last_reboot = Get-ciminstance Win32_OperatingSystem | Select -Exp LastBootUpTime	
# Check if fast boot is enabled: if enabled uptime may be wrong
$Check_FastBoot = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -ea silentlycontinue).HiberbootEnabled 
# If fast boot is not enabled
If(($Check_FastBoot -eq $null) -or ($Check_FastBoot -eq 0))
	{
		$Boot_Event = Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'| where {$_.ID -eq 27 -and $_.message -like "*0x0*"}
		If($Boot_Event -ne $null)
			{
				$Last_boot = $Boot_Event[0].TimeCreated		
			}
	}
ElseIf($Check_FastBoot -eq 1) 	
	{
		$Boot_Event = Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'| where {$_.ID -eq 27 -and $_.message -like "*0x1*"}
		If($Boot_Event -ne $null)
			{
				$Last_boot = $Boot_Event[0].TimeCreated		
			}			
	}		
	
If($Last_boot -eq $null)
	{
		# If event log with ID 27 can not be found we checl last reboot time using WMI
		# It can occurs for instance if event log has been cleaned	
		$Uptime = $Last_reboot
	}
Else
	{
		If($Last_reboot -gt $Last_boot)
			{
				$Uptime = $Last_reboot
			}
		Else
			{
				$Uptime = $Last_boot
			}	
	}
	
$Current_Date = get-date
$Diff_boot_time = $Current_Date - $Uptime
$Boot_Uptime_Days = $Diff_boot_time.Days	
$Hour = $Diff_boot_time.Hours
$Minutes = $Diff_boot_time.Minutes
$Reboot_Time = "$Boot_Uptime_Days days" + ": $Hour hour(s)" + " : $minutes minute(s)"						
If($Boot_Uptime_Days -ge $Reboot_Delay)
	{
		write-output "Last reboot/shutdown: $Reboot_Time"
		write-output "You need to reboot"
		# ***************************************************************************
# 								Part to fill
# ***************************************************************************
# Choose header picture
# By default the picture is the GIF, it will use the GIF provided from my github here below
# damienvanrobaeys/Intune-Proactive-Remediation-scripts/main/Reboot%20warning/reboot.gif
$Header_type = ""
$URL = ""

# You can add you own picture after converting it to base64
# Type the base 64 code in the $Picture_Base64 variable below:
$Picture_Base64 = "data:image/jpeg;base64,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"

# Set toast text
# Use the $Title variable to change the title of the toast
$Title = "This device has not been restarted for "

# Use the $Message variable to change the warning message
$Message = "`nTo ensure machine stability and the timely installation of security updates please consider rebooting this machine."
# Use the $Advice variable to change the advice message
$Advice = "`nIt is recommend that you your restart your computer at least once a week."
# Use the $Text_AppName variable to set your company name
$Text_AppName = "Windows Patching Alert"

# Here belo you can choose to display or not a second button
# This button allows the use to reboot the device
# For this, set the $Show_RestartNow_Button variable to $True or $False
$Show_RestartNow_Button = $True # It will add a button to reboot the device
# ***************************************************************************
# 								Part to fill
# ***************************************************************************




# ***************************************************************************
# 								Export picture
# ***************************************************************************
If($Header_type -eq "GIF")
	{
		$HeroImage = "$env:temp\reboot.gif"		
		#invoke-webrequest -Uri $URL -OutFile $HeroImage -usebasicparsing
	}
Else
	{
		$HeroImage = "$env:TEMP\HeroPicture.png"
		#[byte[]]$Bytes = [convert]::FromBase64String($Picture_Base64)
		#[System.IO.File]::WriteAllBytes($HeroImage,$Bytes)			
	}
	

Function Set_Action
	{
		param(
		$Action_Name		
		)	
		
		$Main_Reg_Path = "HKCU:\SOFTWARE\Classes\$Action_Name"
		$Command_Path = "$Main_Reg_Path\shell\open\command"
		$CMD_Script = "C:\Windows\Temp\$Action_Name.cmd"
		New-Item $Command_Path -Force
		New-ItemProperty -Path $Main_Reg_Path -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null
		Set-ItemProperty -Path $Main_Reg_Path -Name "(Default)" -Value "URL:$Action_Name Protocol" -Force | Out-Null
		Set-ItemProperty -Path $Command_Path -Name "(Default)" -Value $CMD_Script -Force | Out-Null		
	}

$Restart_Script = @'
shutdown /r /f /t 300
'@

$Script_Export_Path = "C:\Windows\Temp"
If($Show_RestartNow_Button -eq $True)
	{
		$Restart_Script | out-file "$Script_Export_Path\RestartScript.cmd" -Force -Encoding ASCII
		Set_Action -Action_Name RestartScript	
	}

Function Register-NotificationApp($AppID,$AppDisplayName) {
    [int]$ShowInSettings = 0

    [int]$IconBackgroundColor = 0
	$IconUri = "C:\Windows\ImmersiveControlPanel\images\logo.png"
	
    $AppRegPath = "HKCU:\Software\Classes\AppUserModelId"
    $RegPath = "$AppRegPath\$AppID"
	
	$Notifications_Reg = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings'
	If(!(Test-Path -Path "$Notifications_Reg\$AppID")) 
		{
			New-Item -Path "$Notifications_Reg\$AppID" -Force
			New-ItemProperty -Path "$Notifications_Reg\$AppID" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
		}

	If((Get-ItemProperty -Path "$Notifications_Reg\$AppID" -Name 'ShowInActionCenter' -ErrorAction SilentlyContinue).ShowInActionCenter -ne '1') 
		{
			New-ItemProperty -Path "$Notifications_Reg\$AppID" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
		}	
		
    try {
        if (-NOT(Test-Path $RegPath)) {
            New-Item -Path $AppRegPath -Name $AppID -Force | Out-Null
        }
        $DisplayName = Get-ItemProperty -Path $RegPath -Name DisplayName -ErrorAction SilentlyContinue | Select -ExpandProperty DisplayName -ErrorAction SilentlyContinue
        if ($DisplayName -ne $AppDisplayName) {
            New-ItemProperty -Path $RegPath -Name DisplayName -Value $AppDisplayName -PropertyType String -Force | Out-Null
        }
        $ShowInSettingsValue = Get-ItemProperty -Path $RegPath -Name ShowInSettings -ErrorAction SilentlyContinue | Select -ExpandProperty ShowInSettings -ErrorAction SilentlyContinue
        if ($ShowInSettingsValue -ne $ShowInSettings) {
            New-ItemProperty -Path $RegPath -Name ShowInSettings -Value $ShowInSettings -PropertyType DWORD -Force | Out-Null
        }
		
		New-ItemProperty -Path $RegPath -Name IconUri -Value $IconUri -PropertyType ExpandString -Force | Out-Null	
		New-ItemProperty -Path $RegPath -Name IconBackgroundColor -Value $IconBackgroundColor -PropertyType ExpandString -Force | Out-Null		
		
    }
    catch {}
}



$Last_reboot = Get-ciminstance Win32_OperatingSystem | Select -Exp LastBootUpTime	
$Check_FastBoot = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -ea silentlycontinue).HiberbootEnabled 
If(($Check_FastBoot -eq $null) -or ($Check_FastBoot -eq 0))
	{
		$Boot_Event = Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'| where {$_.ID -eq 27 -and $_.message -like "*0x0*"}
		If($Boot_Event -ne $null)
			{
				$Last_boot = $Boot_Event[0].TimeCreated		
			}
	}
ElseIf($Check_FastBoot -eq 1) 	
	{
		$Boot_Event = Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'| where {$_.ID -eq 27 -and $_.message -like "*0x1*"}
		If($Boot_Event -ne $null)
			{
				$Last_boot = $Boot_Event[0].TimeCreated		
			}			
	}		
	
If($Last_boot -eq $null)
	{
		$Uptime = $Uptime = $Last_reboot
	}
Else
	{
		If($Last_reboot -gt $Last_boot)
			{
				$Uptime = $Last_reboot
			}
		Else
			{
				$Uptime = $Last_boot
			}	
	}
	
$Current_Date = get-date
$Diff_boot_time = $Current_Date - $Uptime
$Boot_Uptime_Days = $Diff_boot_time.Days		
#**************************************************************************************************************************
# 													TOAST NOTIF PART
#**************************************************************************************************************************
$Title = $Title + " $Boot_Uptime_Days days"

$Scenario = 'reminder' 


$Action_Restart = "RestartScript:"
If(($Show_RestartNow_Button -eq $True))
	{
		$Actions = 
@"
  <actions>
        <action activationType="protocol" arguments="$Action_Restart" content="Restart now" />		
        <action activationType="protocol" arguments="Dismiss" content="Dismiss" />
   </actions>	
"@		
	}
Else
	{
		$Actions = 
@"
  <actions>
        <action activationType="protocol" arguments="Dismiss" content="Dismiss" />
   </actions>	
"@		
	}	


[xml]$Toast = @"
<toast scenario="$Scenario">
    <visual>
    <binding template="ToastGeneric">
        <image placement="hero" src="$HeroImage"/>
        <text placement="attribution">$Attribution</text>
        <text>$Title</text>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$Message</text>
            </subgroup>
        </group>
		
		<group>				
			<subgroup>     
				<text hint-style="body" hint-wrap="true" >$Advice</text>								
			</subgroup>				
		</group>				
    </binding>
    </visual>
	$Actions
</toast>
"@	


$AppID = $Text_AppName
$AppDisplayName = $Text_AppName
Register-NotificationApp -AppID $Text_AppName -AppDisplayName $Text_AppName

# Toast creation and display
$Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$Load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
$ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
$ToastXml.LoadXml($Toast.OuterXml)	
# Display the Toast
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppID).Show($ToastXml)




			
		EXIT 1		
	}
Else
	{
		write-output "Last reboot/shutdown: $Reboot_Time"
		write-output "No need to reboot"			
		EXIT 0
	}	