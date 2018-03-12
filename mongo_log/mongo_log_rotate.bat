set path=%path%;C:\Program Files\MongoDB\Server\3.0\bin;C:\Program Files\MongoDB\bin

mongo < %~dp0\mongo_log_rotate.js
