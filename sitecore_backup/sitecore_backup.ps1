# Set-ExecutionPolicy RemoteSigned

########################################

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

function BackupSitecore($conf)
{
    $BACKUP_TARGET_DIR = $conf["BACKUP_TARGET_DIR"]
    $TARGET_SITE = $conf["TARGET_SITE"]
    $TARGET_DBSVR = $conf["TARGET_DBSVR"]
    $BACKUP_DATABASE = $conf["BACKUP_DATABASE"]
    $WEBSITE_DIR = $conf["WEBSITE_DIR"]

    if (!( Test-Path $BACKUP_TARGET_DIR)) {
        mkdir $BACKUP_TARGET_DIR | Out-Null
    }

    Write-Output "backup dir=$BACKUP_TARGET_DIR"

    if($BACKUP_DATABASE -eq "1")
    {
        Write-Output "start backup database"

        Invoke-Sqlcmd -ServerInstance $TARGET_DBSVR -Query "BACKUP DATABASE ${TARGET_SITE}Sitecore_Core   TO DISK='$BACKUP_TARGET_DIR\${TARGET_SITE}Sitecore_Core.bak' WITH INIT"
        Invoke-Sqlcmd -ServerInstance $TARGET_DBSVR -Query "BACKUP DATABASE ${TARGET_SITE}Sitecore_Master TO DISK='$BACKUP_TARGET_DIR\${TARGET_SITE}Sitecore_Master.bak' WITH INIT"
        Invoke-Sqlcmd -ServerInstance $TARGET_DBSVR -Query "BACKUP DATABASE ${TARGET_SITE}Sitecore_Web    TO DISK='$BACKUP_TARGET_DIR\${TARGET_SITE}Sitecore_Web.bak' WITH INIT"

        Write-Output "complete backup database"
    }

    Write-Output "start backup file"

    Copy-Item -Path ${WEBSITE_DIR}\${TARGET_SITE}\Website\App_Config -Destination $BACKUP_TARGET_DIR -Recurse -Force

    Copy-Item -Path ${WEBSITE_DIR}\${TARGET_SITE}\Website\bin -Destination $BACKUP_TARGET_DIR -Recurse -Force

    Copy-Item -Path ${WEBSITE_DIR}\${TARGET_SITE}\Website\layouts $BACKUP_TARGET_DIR -Recurse -Force

    Copy-Item -Path ${WEBSITE_DIR}\${TARGET_SITE}\Website\Web.config $BACKUP_TARGET_DIR -Force

    Write-Output "complete backup file"
}

function Main()
{
    $Error.Clear()

    #$SCRIPT_NAME = $script:MyInvocation.MyCommand.Path
    $BASE_DIR = & { Split-Path -Parent $MyInvocation.ScriptName }
    $NOW_KEY = [DateTime]::Now.ToString("yyyyMMdd_HHmmss");
    $SCRIPT_NAME = & { $MyInvocation.ScriptName }

    $INI_PATH = $SCRIPT_NAME -replace (".ps1", ".ini")

    if(!(Test-Path $INI_PATH))
    {
        Write-Output "Error: Invalid INI_PATH $INI_PATH"
        Return
    }

    $INI = LoadIni $INI_PATH

    if($INI["BACKUP_DIR"] -eq $Null)
    {
        $INI["BACKUP_DIR"] = $BASE_DIR
    }

    if($INI["WEBSITE_DIR"] -eq $Null)
    {
        $INI["WEBSITE_DIR"] = "C:\inetpub\wwwroot"
    }

    $BACKUP_DIR = $INI["BACKUP_DIR"]
    $BACKUP_KEY = $INI["BACKUP_KEY"]
    $LOG_DIR = $INI["LOG_DIR"]
    $BACKUP_TARGET_DIR = $INI["BACKUP_TARGET_DIR"]

    if (!( Test-Path $BACKUP_DIR))
    {
        Write-Output "Error: Invalid BACKUP_DIR $BACKUP_DIR"
        Return
    }

    if($BACKUP_KEY -eq $null)
    {
        $BACKUP_KEY = $NOW_KEY
    }

    if($BACKUP_TARGET_DIR -eq $null)
    {
        $BACKUP_TARGET_DIR = (Join-Path $BACKUP_DIR $BACKUP_KEY).ToString()
        $INI["BACKUP_TARGET_DIR"] = $BACKUP_TARGET_DIR
    }

    if($LOG_DIR -eq $null)
    {
        $LOG_DIR = Join-Path $BACKUP_DIR "log"
    }

    if (!( Test-Path $LOG_DIR))
    {
        mkdir $LOG_DIR | Out-Null
    }

    $log_path = Join-Path $LOG_DIR "backup${NOW_KEY}.log"

    start-transcript $log_path

    $ErrorActionPreference = "Stop"

    try
    {
        BackupSitecore $INI
    }
    catch
    {
        Write-Output "Error: BackupSitecore failed"
        Write-Output $Error
    }

    stop-transcript
}

Main

