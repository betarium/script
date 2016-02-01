powershell "start -Verb runas powershell 'start taskkill ''/im gwx.exe /F'''"

powershell "start -Verb runas powershell 'start wusa ''/uninstall /kb:3035583 /norestart /quiet'''"

powershell "start -Verb runas powershell '(New-Object -com ''Microsoft.Update.Session'').CreateUpdateSearcher().Search(''IsInstalled=0'').Updates | ForEach-Object{ if($_.Title -match ''3035583''){ $_.IsHidden=1; }}'"

