# Get New computer name from user
$NewCompName = read-host "Please enter New Computer Name"

# Set computer name to variabl "$NewCompName"
$sysInfo = Get-WmiObject -Class Win32_ComputerSystem
$sysInfo.Rename("$NewCompName")

# Keep Scripts from running in future
Set-ExecutionPolicy Restricted

# Reboot Machine
Restart-Computer