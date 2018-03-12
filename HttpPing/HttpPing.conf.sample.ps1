########################################

$TARGET_URL = "http://example.com"

$RETRY_WAIT = 10

########################################

#$MAIL_ENABLE = 0

$MAIL_SUBJECT = "HttpPingアラート"
$MAIL_MESSAGE = "HttpPingでエラーがありました。\n\n" +
    "URL: %URL%\n\n" +
    "Message:\n%MESSAGE%\n\n" +
    "Host:" + $Env:COMPUTERNAME + "`n"

$MAIL_FROM = "test@example.com"
$MAIL_TO = "test@example.com"

########################################

$MAIL_SMTP_SERVER = "mail.example.com"

$MAIL_SMTP_PORT = 587
$MAIL_SMTP_SSL = 1

$MAIL_SMTP_USER = "example"
$MAIL_SMTP_PASSWORD = "example"
