set path=C:\Program Files\Git\bin;C:\Program Files (x86)\Git\bin;%path%;C:\Program Files\Git\usr\bin

set SSH_DIR=%USERPROFILE%\.ssh

mkdir %SSH_DIR%

if exist %SSH_DIR%\id_rsa exit /b

rem ssh-keygen -t rsa -N "" -P "" -f %SSH_DIR%\id_rsa -C %USERNAME%
ssh-keygen -t ed25519 -N "" -P "" -f %SSH_DIR%\id_rsa -C %USERNAME%

explorer %SSH_DIR%

pause
