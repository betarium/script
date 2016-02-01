# Set-ExecutionPolicy RemoteSigned

Param (
    [string]$Subject = "",
    [string]$Message = ""
)

function LoadIni($filename)
{
    $result = @{}
    $lines = get-content $filename
    foreach($line in $lines)
    {
        if($line -match "^;")
        {
            continue
        }
        $param = $line.split("=",2)
        $result[$param[0]] = $param[1]
    }
    return $result
}

function SendMail($conf, $mailSubject, $mailBody)
{
    $credential = $null
    if($conf["SmtpUser"] -ne "" -and $conf["SmtpPassword"] -ne "")
    {
        $password = ConvertTo-SecureString $conf["SmtpPassword"] -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($conf["SmtpUser"], $password)
    }

    $mailTo = $conf["MailTo"]
    $mailTo = $mailTo -split ","
    $mailBody = $mailBody.Replace("\n", "`n")

    $SmtpUseSsl = $conf["SmtpUseSsl"]

    if($SmtpUseSsl -eq "1")
    {
        $SmtpUseSsl = $true
    }
    else
    {
        $SmtpUseSsl = $false
    }

    Send-MailMessage -To $mailTo -From $conf["MailFrom"] `
        -Subject $mailSubject -Body $mailBody `
        -SmtpServer $conf["SmtpServer"] -Port $conf["SmtpPort"] -UseSsl:$SmtpUseSsl `
        -Credential $credential -Encoding UTF8
}

function Main($scriptPath, $Subject, $Message)
{
	Write-Output "Start SendMail."

	$INI_PATH = ([System.IO.Path]::ChangeExtension($scriptPath, ".ini"))

	$INI = LoadIni $INI_PATH

	if($Subject -eq "")
	{
		$Subject = $INI["MailSubject"]
	}
	if($Message -eq "")
	{
		$Message = $INI["MailMessage"]
	}
	$Message += "`n`n" + "Host:" + $Env:COMPUTERNAME + "`n"

	SendMail $INI $Subject $Message

	Write-Output ("Complete SendMail. mailto=" + $INI["MailTo"])
}


try
{
	$ErrorActionPreference = "stop"
	$error.clear()
	start-transcript ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, ".log"))

	Main $MyInvocation.MyCommand.Path $Subject $Message

	Exit 0
}
catch [Exception]
{
	Write-Output "SendMail Error"
	Write-Output $error
	Exit -1
}
finally
{
	stop-transcript
}
