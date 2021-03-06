'==========================================================================
'
' NAME: StageDockingLANDriver.vbs
'
' AUTHOR: Brian Gonzalez, Panasonic 
' DATE  : 7/13/2012
'
' COMMENT:
'	Performs:
'	-Add Docking Station drivers to subDirectory of C:\Windows\inf
'	-Updates the DevicePath registry entry with newly copied driver folder.
'
'	Returns:
'	0 = No Errors
'	1 = Driver folder "lan9500-x86-n51f" not found.
'	2 = Copy of driver folder did not complete.
'	3 = Failed to read the current DevicePath value from registry.
'	4 = Failed to update registry.
'
'==========================================================================

On Error Resume Next
dim objFSO, objFile, objShell

set objFSO = CreateObject("Scripting.FileSystemObject")
set objShell = CreateObject("WScript.Shell")
strScriptFolder = objFSO.GetParentFolderName(WScript.ScriptFullName) 'No trailing backslash

strDockingDriverFolderPath = strScriptFolder & "\lan9500-x86-n51f"
strTargetDir = "C:\Windows\inf\dockingdrivers"
If objFSO.FolderExists(strDockingDriverFolderPath) Then
	objFSO.CopyFolder strDockingDriverFolderPath, strTargetDir, True
	If Err.Number <> 0 Then
		WScript.Quit(2)
	End If
Else
	WScript.Quit(1)
End If

strRegValPath = "HKLM\Software\Microsoft\Windows\CurrentVersion\DevicePath"
strCurrDevicePath = objShell.RegRead(strRegValPath)
If strCurrDevicePath = "" Then
	WScript.Quit(3)
End If

objShell.RegWrite strRegValPath, strCurrDevicePath & ";" & strTargetDir, "REG_EXPAND_SZ"
If Err.Number <> 0 Then
	WScript.Quit(4)
Else
	WScript.Quit(0)
End If
