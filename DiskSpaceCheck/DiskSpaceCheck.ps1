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
    if($conf["MailTo"] -eq ""){
        return
    }

    $mailTo = $conf["MailTo"]
    $mailTo = $mailTo -split ","

    $password = ConvertTo-SecureString $conf["SmtpPassword"] -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($conf["SmtpUser"], $password)

    $SmtpUseSsl = $conf["SmtpUseSsl"]

    if($SmtpUseSsl -eq "true")
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

function Main($scriptPath)
{
    Write-Output "Start Disk Check."

    $INI_PATH = [System.IO.Path]::ChangeExtension($scriptPath, ".ini")

    $INI = LoadIni $INI_PATH

    $subject = $INI["MailSubject"]

    $FreeSpace = (Get-PSDrive C).Free
    $FreeSpace = $FreeSpace / 1024 / 1024 / 1024
    $FreeSpace = [math]::Truncate($FreeSpace)

    $FreeSpaceFormat = $FreeSpace.ToString("#,###")
    $FreeSpaceFormat = $FreeSpaceFormat + " GB"

    Write-Output ("Free Space= " + $FreeSpaceFormat)

    $localAddress = (Get-NetIPAddress | where AddressFamily -eq "IPv4")
    $localAddress = ($localAddress | where IPAddress -ne "127.0.0.1" | select -ExpandProperty IPAddress)

    $MAIL_PATH = [System.IO.Path]::ChangeExtension($scriptPath, ".txt")
    $message = [System.IO.File]::ReadAllText($MAIL_PATH, [System.Text.Encoding]::Default);

    $message = $message.Replace("%FREE_SPACE_FORMAT%", $FreeSpaceFormat)
    $message = $message.Replace("%SERVER_NAME%", $Env:COMPUTERNAME)
    $message = $message.Replace("%SERVER_ADDRESS%", $localAddress)

    SendMail $INI $subject $message

    Write-Output ("Complete Disk Check. mailto=" + $INI["MailTo"])
}


try
{
    $ErrorActionPreference = "stop"
    $error.clear()

    Main $MyInvocation.MyCommand.Path

    Exit 0
}
catch [Exception]
{
    Write-Output "Disk Check Error"
    Write-Output $error
    Exit -1
}
