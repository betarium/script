########################################
Param($TARGET_URL)

$SCRIPT_NAME = &{ $MyInvocation.ScriptName }
$SCRIPT_DIR = Split-Path -Parent $SCRIPT_NAME
$SCRIPT_CONF_PATH = ([System.IO.Path]::ChangeExtension($SCRIPT_NAME, ".conf.ps1"))

########################################

$STARTUP_DATE = [DateTime]::Now.ToString("yyyyMMdd_HHmmss")

$LOG_DATE = [DateTime]::Now.ToString("yyyyMM")

$LOG_NAME = Split-Path -Leaf $SCRIPT_NAME
$LOG_NAME = ([System.IO.Path]::ChangeExtension($LOG_NAME, "." + $LOG_DATE + ".log"))

$LOG_DIR = $SCRIPT_DIR
$LOG_DIR = Join-Path $LOG_DIR "~log"
$LOG_PATH = Join-Path $LOG_DIR $LOG_NAME

$RETRY_COUNT = 4
$RETRY_WAIT = 10

#$VerbosePreference = "Continue"
#$DebugPreference = "Continue"

########################################

if(Test-Path $SCRIPT_CONF_PATH)
{
    . $SCRIPT_CONF_PATH
}

if($TARGET_URL -ne $null)
{
    Write-Verbose("Set parameter. " + $TARGET_URL)
    $TARGET_URL = $TARGET_URL
}

########################################

if(-not (Test-Path $LOG_DIR -PathType container))
{
    Write-Verbose("mkdir: " + $LOG_DIR)
    $dummy = mkdir $LOG_DIR
}

start-transcript $LOG_PATH -Append | Write-Verbose

$InformationPreference = "Continue"
#$VerbosePreference = "Continue"

#Write-Information("Invoke-WebRequest url=" + $TARGET_URL)
Write-Host("Invoke-WebRequest url=" + $TARGET_URL)

$resultCode = -1
$errorMessage = $null

$testCount = 0

While($testCount++ -ne $RETRY_COUNT)
{
    try
    {
        Write-Host("Request try ... date=" + [DateTime]::Now)
        $response = Invoke-WebRequest -Uri $TARGET_URL -UseBasicParsing

        if($response -isnot [Microsoft.PowerShell.Commands.HtmlWebResponseObject] -and $response -isnot [Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject])
        {
            Write-Error("Invoke-WebRequest faild. Unknown Response type. type=" + $response.GetType().FullName)
            $errorMessage = "Unknown Response."
        }
        elseif($response.StatusCode -ne 200)
        {
            Write-Error("Invoke-WebRequest faild. date=" + [DateTime]::Now + " Status=" + $response.StatusCode)
            $errorMessage = "ErrorStatus=" + $response.StatusCode
            $resultCode = 1
        }
        else
        {
            #Write-Information("Status=" + $response.StatusCode + " date=" + [DateTime]::Now)
            Write-Host("Status=" + $response.StatusCode + " date=" + [DateTime]::Now)

            Write-Verbose("Invoke-WebRequest success.")

            $resultCode = 0
            break
        }
    }
    catch
    {
        $errorMessage += $_.Exception.ToString() + "`n";
        Write-Error("Invoke-WebRequest faild. date=" + [DateTime]::Now + "`n" + $_.Exception)
    }

    if($testCount + 1 -ne $RETRY_COUNT)
    {
        Write-Verbose("Sleep...")
        Sleep $RETRY_WAIT
        Write-Verbose("Sleep done.")
    }
}

if($resultCode -ne 0 -and $MAIL_ENABLE)
{
    $password = ConvertTo-SecureString $MAIL_SMTP_PASSWORD -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($MAIL_SMTP_USER, $password)

    $mailToList = $MAIL_TO -split ","
    $mailMessageFormat = $MAIL_MESSAGE.Replace("\n", "`n")
    $mailMessageFormat = $mailMessageFormat.Replace("%URL%", $TARGET_URL)
    $mailMessageFormat = $mailMessageFormat.Replace("%MESSAGE%", $errorMessage)

    $mailSmtpSslFlag = $False
    if($MAIL_SMTP_SSL)
    {
        $mailSmtpSslFlag = $true
    }

    Write-Host("Send Mail. to=" + $MAIL_TO)
    Write-Verbose("Mail:" + $mailMessageFormat)

    Send-MailMessage -From $MAIL_FROM -To $mailToList `
        -Subject $MAIL_SUBJECT -Body $mailMessageFormat `
        -SmtpServer $MAIL_SMTP_SERVER -Port $MAIL_SMTP_PORT -UseSsl:$mailSmtpSslFlag `
        -Credential $credential -Encoding UTF8

    Write-Verbose("Send Mail complete.")
}

stop-transcript | Write-Verbose

#pause

exit $resultCode

