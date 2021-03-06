# Script Reads a .CSV file and installs listed commands and checks
#	against file or registry to ensure install completed.
#############################################################################c
#==========Variables==================================
$oInvocation = (Get-Variable MyInvocation).Value
$sCurrentDirectory = Split-Path $oInvocation.MyCommand.Path
$sLogLocation = "$sCurrentDirectory\InstallScript.log"
$sCVSPath = "$sCurrentDirectory\PoliceUser.csv"
$ErrorActionPreference = "SilentlyContinue"
#==========Functions==================================
Function fWriteToLog($sUpdateMessage){
	$sDate = Get-Date -Format "MM/dd/yyyy"
    $sTime = Get-Date -Format "hh:mm:ss"
    $sUpdateMessage = "$sDate $sTime : $sUpdateMessage"
    $sUpdateMessage | Write-Host ;$sUpdateMessage | Out-File -FilePath $sLogLocation -Append
}
Function fRunCommand($sFullCommandLine, $sCheckPath){
	If (($sCheckPath -eq "") -or (!(Test-Path $sCheckPath))){
	trap {fWriteToLog "No checkpath specified."; Continue}
	$sCommandLineEXE = (($sFullCommandLine -Split ".exe")[0]) + ".exe"
	If ($sFullCommandLine.Length -gt $sCommandLineEXE.Length){
	$sCommandLineARG = $sFullCommandLine.SubString($sCommandLineEXE.Length, `
		$sFullCommandLine.Length - $sCommandLineEXE.Length).Trim()
	} Else {$sCommandLineARG = ""}
	fWriteToLog "Executing Command: $sCommandLineEXE`r`n",`
	"With Argument: $sCommandLineARG"
	&$sCommandLineEXE $sCommandLineARG # Executing Command with Argument
	fWriteToLog "Command completed and returned with a $?."
	If ($sCheckPath -ne ""){
		fWriteToLog "Verification will now begin using $sCheckPath"
		For($i=1; $i -le 31; $i++)
		{
            If (Test-Path $sCheckPath) #If Checkfile is found For Loop will break
				{fWriteToLog "Install is complete and verified.`r`n";break}
           	fWriteToLog "Delay $i/45 minutes..."
			Start-Sleep -Seconds 60 #Check for completion of install every minute
			If ($i -eq 30){
           	fWriteToLog "Verification of Install did not complete in the alloted "`
           	" 30 minute time period.  Restarting Computer..."
           	Restart-Computer}
		}
	} Else {fWriteToLog "No installation verification check passed to fStartProcess..."}
	} Else {fWriteToLog "Application ($sCheckPath) is already installed, skipping install..."}
}
#==========Main Execution==================================
If (Test-Path $sCVSPath){
	# Reads CVS and skips the 1st line
	Get-Content $sCVSPath | Select-Object -Skip 1 |
	foreach{
	# Each line is split in 2, 1 for command line and 1 for check path
	$sFullCommandLine = ($_.Split(",")[0])
	# If checkpath is specified, then get rid of the quotes
	If (($_.Split(",")[1]) -gt 0){
	$sCheckPath = $_.Split(",")[1].Replace("""", "")
	# If NO checkpath is found, create an empty $sCheckPath var
	} else {fWriteToLog "No CheckPath found in CSV. Verification will be skipped for`r`n",`
	"$sFullCommandLine"; $sCheckPath = ""}
	# call fRunCommand function to execute command for line
	fRunCommand $sFullCommandLine $sCheckPath
	}
}
################Example .CSV Input#########################
<#
Command String,File or Folder Check
CMD.exe /c echo This is command #1>"D:\T\CommandNum1.txt",D:\T\CommandNum1.txt
CMD.exe /c echo This is command #2>"D:\T\CommandNum2.txt"
CMD.exe /c echo This is command #3>"D:\T\CommandNum3.txt",D:\T\CommandNum3.txt
#>
############################################################