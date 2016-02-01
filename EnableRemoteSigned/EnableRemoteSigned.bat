powershell "start -Verb runas powershell.exe ""-NoExit Set-ExecutionPolicy RemoteSigned -Scope LocalMachine`nGet-ExecutionPolicy -Scope LocalMachine"""
