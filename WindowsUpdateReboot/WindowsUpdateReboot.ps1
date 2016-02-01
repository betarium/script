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
    if($conf["MailEnable"] -ne "1")
    {
        return;
    }

    $password = ConvertTo-SecureString $conf["SmtpPassword"] -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($conf["SmtpUser"], $password)

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

$INI_PATH = ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, ".ini"))
$BASE_PATH = $MyInvocation.MyCommand.Path
$BASE_PATH = Split-Path -Parent $BASE_PATH

start-transcript ($MyInvocation.MyCommand.Path + ".log")

$message = "Start Windows update check."
Write-Output $message

$INI = LoadIni $INI_PATH

$MailFooter = "`n`n" + "Host:" + $Env:COMPUTERNAME + "`n"

$Session = New-Object -com "Microsoft.Update.Session"
$Search = $Session.CreateUpdateSearcher()
$SearchResults = $Search.Search("IsInstalled=0 and IsHidden=0 and AutoSelectOnWebSites=1")

$AvailableUpdates = $SearchResults.Updates

if($AvailableUpdates.count -eq 0){
    $message = "No update patch."
    Write-Output $message
    #SendMail $INI "No update - WindowsUpdate.ps1" ($message + $MailFooter)
    Exit
}

$UpdateCount = $AvailableUpdates.count
Write-Output "$UpdateCount patch found(s)."

#Write-Output "Start download."

$DownloadCollection = New-Object -com "Microsoft.Update.UpdateColl"

$patchDetail = ""

$AvailableUpdates | ForEach-Object {
    Write-Output ("  Patch: " + $_.Title)

    if ($_.InstallationBehavior.CanRequestUserInput -ne $TRUE) {
        $patchDetail = $patchDetail + $_.Title + "`n"
        $DownloadCollection.Add($_) | Out-Null
    }
    else {
        Write-Output "  Required user input."
    }
    if ($_.InstallationBehavior.RebootBehavior -gt 0) {
        Write-Output "  Required reboot."
    }
}

$message = "Windows Update start."
Write-Output $message
SendMail $INI "Update start - WindowsUpdate.ps1" ($message + "`n`n[Patch]`n" + $patchDetail + "`n" + $MailFooter)

$Downloader = $Session.CreateUpdateDownloader()
$Downloader.Updates = $DownloadCollection
$Downloader.Download()

Write-Output "Finish download."

Write-Output "Start update."

$InstallCollection = New-Object -com "Microsoft.Update.UpdateColl"
$AvailableUpdates | ForEach-Object {
    #if ($_.IsDownloaded) {
    if ($_.IsDownloaded && Not($_.IsHidden)) {
        $InstallCollection.Add($_) | Out-Null
    }
}

$Installer = $Session.CreateUpdateInstaller()
$Installer.Updates = $InstallCollection
$Results = $Installer.Install()


$message = "Windows Update complete."
Write-Output $message

$mailTitle = "Update complete"
$rebootMessage = ""
if ($Results.RebootRequired) {
    $mailTitle = "Update complete & Reboot"
}

SendMail $INI ($mailTitle + " - WindowsUpdate.ps1") ($message + "`n`n[Patch]`n" + $patchDetail + "`n" + $MailFooter)

if ($Results.RebootRequired) {
    Write-Output "Reboot."
    stop-transcript
    Restart-Computer -Force
}

stop-transcript

