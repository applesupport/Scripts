#Grab Current Directory
$oInvocation = (Get-Variable MyInvocation).Value
$sCurrentDirectory = Split-Path $oInvocation.MyCommand.Path

#If ((Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem").model -Match "CF-53J.*"){}
#If ((Get-WmiObject -Query "SELECT * FROM Win32_BaseBoard").product -Match "CF53-2*"){}

#If ((Test-Path "D:\Applications\IE9_IEAK.msi") -ne "true") {Write-Host "Its there!! .."}
#or
#If (!(Test-Path "D:\Applications\IE9_IEAK.msi")) {Write-Host "Its not there!! .."}
#or
#If (-not(Test-Path "D:\Applications\IE9_IEAK.msi")) {Write-Host "Its not there!! .."}

#Test-Path can NOT check for existance of Key Properties, only the Keys themselves...
#Test-Path "HKLM:\SOFTWARE\Clients\Diagraming\Microsoft Visio\Capabilities\ApplicationDescription"

#Create/Update Reg Key
#New-Item -Path "HKLM:\SOFTWARE\Clients\Diagraming\Microsoft Visio\Capabilities\NewKey" -Value "Default Value" -Force

#Create/Update Reg Value
#Set-ItemProperty -Path "HKLM:\SOFTWARE\Clients\Diagraming\Microsoft Visio\Capabilities\NewKey" -Name "NotATrueNam" -Value "New Value"

#Loop Script with included sleep and file check
#For($i=1; $i -le 5; $i++)
#{
#	If (Test-Path "D:\Applications\ExitLoop.txt"){break}
#	Start-Sleep -Seconds 10
#}

<# ####BLOCK OF CODE TO QUERY MODEM BEGIN
Function fQueryModem($sQueryString, $sRegExp) {
$oComPort = New-Object System.IO.Ports.SerialPort $sComPortNumber,$sComPortSpeed,None,8,1
$oComPort.Open()
$oComPort.Write("AT")
$oComPort.Write($sQueryString + "`r")
Start-Sleep -m 50
$tVar = $oComPort.ReadExisting()
$tVar = ($tVar -replace "OK","").trim()
$oComPort.Close()

If (!($sRegExp -eq "")) {$tVar -Match $sRegExp|Out-Null; $tVar = $Matches[0]}
return $tVar
}

#AT Commands to pull information from Modems
#"MEID", "+CGSN"			#i.e. "990000780252708"
#"Modem Model", "+CGMM"		#i.e. "MC7750"
#"Phone Number", "+CNUM"	#i.e. "+CNUM: "Line 1","+15514972305",145"
#"SIM", "+ICCID"			#i.e. "ICCID: 89148000000148583496"
#"All Commands", "+CLAC"

#Grab COMPort number and max ComPort speed
$sComPortNumber = Get-WMIObject Win32_PotsModem | `
	Where-Object {$_.DeviceID -like "USB\VID*" -and $_.Status -like "OK"} | `
	foreach {$_.AttachedTo}
$sComPortSpeed = Get-WMIObject Win32_PotsModem | `
	Where-Object {$_.DeviceID -like "USB\VID*" -and $_.Status -like "OK"} | `
	foreach {$_.MaxBaudRateToSerialPort}

#Populate Variables using fQueryModem Function Call
$sMEID = fQueryModem "+CGSN" "\d{15}"
$sModemModel = fQueryModem "+CGMM" "" #Match Everything
$sPhoneNumber = fQueryModem "+CNUM" "\d{11}"
$sSIM = fQueryModem "+ICCID" "\d{20}"

#Populate TXT file with captured variables
$sOutString = "Date: Get-Date`r`nUsername: $env:username`r`nMEID: $sMEID`r`nModem Model: $sModemModel" `
"`r`nPhone Number: $sPhoneNumber`r`nSIM Number: $sSIM" `
$sOutString | Out-File -FilePath "$sCurrentDirectory\ModemInformation.TXT" -Force
#> ####BLOCK OF CODE TO QUERY MODEM END

<# ####BLOCK OF CODE TO INSTALL SQL SERVER 2008 R2
Function WaitForFile($sFileName)
{
	#Loop Script with included sleep and file check
	For($i=1; $i -le 30; $i++)
	{
		If (Test-Path $sFileName){break}
		Start-Sleep -Seconds 60 #Checks for existance of file every minute
	}
}

#Install SQL 2008 R2
If (!(Test-Path("C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLEXPRESS\MSSQL\DATA\MSDBLog.ldf")))
{
	#Copy Install Files to C:\Windows\Temp
    If (!(Test-Path("C:\Windows\Temp\SQL08R2\x64\setup\sql_common_core_msi\pfiles32\sqlservr\100\com\kdz5mbsd.dll"))) {
    Copy-Item "$sCurrentDirectory\" "C:\Windows\Temp\SQL08R2\" -recurse
    }
    #Start Installation
    C:\Windows\Temp\SQL08R2\setup.exe /Q /IACCEPTSQLSERVERLICENSETERMS /SAPWD="P@ssw0rd" /ConfigurationFile="C:\Windows\Temp\SQL08R2\ConfigurationFile.ini"
    WaitForFile("C:\Windows\Temp\SQL08R2\x64\setup\sql_common_core_msi\pfiles32\sqlservr\100\com\kdz5mbsd.dll")
} else {Write-Host "SQL Already Installed."}
#> ####BLOCK OF CODE TO INSTALL SQL SERVER 2008 R2


<#  Folder Permissions Testing.. Not functional
#Create a folder
If (!(Test-Path D:\Folder)) {New-Item D:\Folder –Type Directory}
#Query inherited permissions of folder
#Get-Acl D:\Folder | Format-List


$dir = D:\Folder
$acl = Get-Item $dir |get-acl

$rule = New-Object System.Security.AccessControl.FileSystemAccessRule -ArgumentList @("Users","ReadAndExecute","Allow")
$acl.SetAccessRule($rule) ;$acl |Set-Acl
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule -ArgumentList @("Administrators","ReadAndExecute","Allow")
$acl.SetAccessRule($rule) ;$acl |Set-Acl

Get-Acl D:\Folder  | Format-List
#>

# Function reads a CSV (skips header row) and pulls commands and check paths
#	then runs the command and checks the path.
$sLogLocation = "$sCurrentDirectory\InstallScript.log"
Function fWriteToLog($sMessage){
	$sDate = Get-Date -Format "MM/dd/yyyy"
    $sTime = Get-Date -Format "hh:mm:ss"
    $tMessage = "$sDate $sTime : $sMessage"
    $tMessage | Write-Host ;$tMessage | Out-File -FilePath $sLogLocation -Append}
Function fRunCommand($sFullCommandLine, $sCheckPath){
	$sCommandLineEXE = (($sFullCommandLine -Split ".exe")[0]) + ".exe"
	$sCommandLineARG = $sFullCommandLine.SubString($sCommandLineEXE.Length, $sFullCommandLine.Length - $sCommandLineEXE.Length).Trim()
	&$sCommandLineEXE $sCommandLineARG # Executing Command with Argument
	If ((Test-Path $sCheckPath).length -ne 0)
	{
		For($i=1; $i -le 31; $i++)
		{
            If (Test-Path $sCheckPath) #If Checkfile is found For Loop will break
				{fWriteToLog "Install is complete and verified.`r`n";break}
            fWriteToLog "Delay $i/45 minutes..."
			Start-Sleep -Seconds 60 #Check for completion of install every minute
			If ($i -eq 30){
            fWriteToLog "Verification of Install did not complete in the alloted 30 minute time period.  Restarting Computer..."
            Restart-Computer}
		}
	} Else {fWriteToLog "No installation verification check passed to fStartProcess..."}
}
$sCvsPath = "$sCurrentDirectory\PoliceUser.csv"
If (Test-Path $sCvsPath){
Get-Content $sCvsPath | Select-Object -Skip 1 |
foreach{
	$sFullCommandLine = ($_.Split(",")[0])
	$sCheckFile = $_.Split(",")[1].Replace("""", "")
	fRunCommand $sFullCommandLine $sCheckFile
	}
}