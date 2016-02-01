rem 右クリックして"管理者として実行"

taskkill /im gwx.exe /F

reg add HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate /f /v "DisableOSUpgrade" /t REG_DWORD /d 00000001
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Gwx /f /v "DisableGwx" /t REG_DWORD /d 00000001

wusa.exe /uninstall /kb:3035583 /norestart /quiet
wusa.exe /uninstall /kb:2952664 /norestart /quiet

powershell "%~dp0\win10kill.ps1"

pause
