cd /d %~dp0

set now=%date:/=%_%time::=%
set now=%now:~0,15%

mkdir %now%

pause
