set path=C:\Program Files\Git\bin;C:\Program Files (x86)\Git\bin;%path%

set SSH_DIR=%USERPROFILE%\.ssh

mkdir %SSH_DIR%

if exist %SSH_DIR%\id_rsa exit /b

ssh-keygen -t rsa -N "" -P "" -f %SSH_DIR%\id_rsa -C %USERNAME%

explorer %SSH_DIR%

pause
