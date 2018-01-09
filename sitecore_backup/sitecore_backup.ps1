# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

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

function BackupWebsite($conf)
{
    $BACKUP_TARGET_DIR = $conf["BACKUP_TARGET_DIR"]
    $BACKUP_SITE = $conf["BACKUP_SITE"]
    $TARGET_DBSVR = $conf["TARGET_DBSVR"]
    $BACKUP_DATABASE = $conf["BACKUP_DATABASE"]
    $BACKUP_WEBSITE_DIR = $conf["BACKUP_WEBSITE_DIR"]
    $BACKUP_WEBSITE_RESOURCE_LIST = $conf["BACKUP_WEBSITE_RESOURCE_LIST"]
    $BACKUP_WEBSITE_DLL = $conf["BACKUP_WEBSITE_DLL"]

    #if (!( Test-Path $BACKUP_TARGET_DIR)) {
    #    mkdir $BACKUP_TARGET_DIR | Out-Null
    #}

    $target_dir = Join-Path $BACKUP_TARGET_DIR "Website"

    mkdir $target_dir | Out-Null

    if ($BACKUP_WEBSITE_DLL -eq $null) {
        $BACKUP_WEBSITE_DLL = "*.dll"
    }

#    Write-Output "backup dir=$BACKUP_TARGET_DIR"
#
#    if($BACKUP_DATABASE -eq "1")
#    {
#        Write-Output "start backup database"
#
#        Invoke-Sqlcmd -ServerInstance $TARGET_DBSVR -Query "BACKUP DATABASE ${BACKUP_SITE}Sitecore_Core   TO DISK='$BACKUP_TARGET_DIR\${BACKUP_SITE}Sitecore_Core.bak' WITH INIT"
#        Invoke-Sqlcmd -ServerInstance $TARGET_DBSVR -Query "BACKUP DATABASE ${BACKUP_SITE}Sitecore_Master TO DISK='$BACKUP_TARGET_DIR\${BACKUP_SITE}Sitecore_Master.bak' WITH INIT"
#        Invoke-Sqlcmd -ServerInstance $TARGET_DBSVR -Query "BACKUP DATABASE ${BACKUP_SITE}Sitecore_Web    TO DISK='$BACKUP_TARGET_DIR\${BACKUP_SITE}Sitecore_Web.bak' WITH INIT"
#
#        Write-Output "complete backup database"
#    }

    Write-Output "Start backup website."

    Copy-Item -Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\App_Config -Destination $target_dir -Recurse -Force

    Copy-Item -Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\bin -Destination $target_dir -Filter $BACKUP_WEBSITE_DLL -Recurse -Force

    Copy-Item -Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\layouts $target_dir -Recurse -Force

    if(Test-Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\Areas)
    {
        Copy-Item -Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\Areas $target_dir -Recurse -Force
    }

    if(Test-Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\Views)
    {
        Copy-Item -Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\Views $target_dir -Recurse -Force
    }

    Copy-Item -Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\Web.config $target_dir -Force

    if ($BACKUP_WEBSITE_RESOURCE_LIST -ne "" -and $BACKUP_WEBSITE_RESOURCE_LIST -ne $null) {
        foreach($path in $BACKUP_WEBSITE_RESOURCE_LIST -Split ","){
            if(-Not (Test-Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\$path))
            {
                Continue
            }

            if(Test-Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\$path -PathType Container)
            {
                Copy-Item -Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\$path $target_dir -Recurse -Force
            }
            else
            {
                Copy-Item -Path ${BACKUP_WEBSITE_DIR}\${BACKUP_SITE}\Website\$path $target_dir -Force
            }
        }
    }

    Write-Output "Complete backup website."
}

function BackupDatabase($conf)
{
    $BACKUP_TARGET_DIR = $conf["BACKUP_TARGET_DIR"]
    $BACKUP_SITE = $conf["BACKUP_SITE"]
    $BACKUP_DATABASE_LIST = $conf["BACKUP_DATABASE_LIST"]
    $BACKUP_DATABASE_SERVER = $conf["BACKUP_DATABASE_SERVER"]

    $target_dir = Join-Path $BACKUP_TARGET_DIR "Database"

    mkdir $target_dir | Out-Null

    Write-Output "Start backup database."

    $databaseList = $BACKUP_DATABASE_LIST -split ","

    foreach($databaseTemp in $databaseList)
    {
        $database = $databaseTemp
        $database = $database -replace ("%BACKUP_SITE%", "${BACKUP_SITE}")
        Write-Output "  Backup database [${database}] ..."
        $backupPath = "$target_dir\${database}.bak"

        if (( Test-Path $backupPath))
        {
            del $backupPath
        }

        sqlcmd -S $BACKUP_DATABASE_SERVER -Q "BACKUP DATABASE ${database} TO DISK='${backupPath}' WITH INIT"
    }

    Write-Output "Complete backup database."
}

function CompressZip($conf)
{
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $BACKUP_TARGET_DIR = $conf["BACKUP_TARGET_DIR"]
    $BACKUP_ZIP_PATH = $INI["BACKUP_ZIP_PATH"]

    Write-Output "Start compress. BACKUP_ZIP_PATH=$BACKUP_ZIP_PATH"

    if (( Test-Path $BACKUP_ZIP_PATH)) {
        del $BACKUP_ZIP_PATH
    }

    [System.IO.Compression.ZipFile]::CreateFromDirectory($BACKUP_TARGET_DIR, $BACKUP_ZIP_PATH)

    rmdir -Recurse -Force $BACKUP_TARGET_DIR

    Write-Output "Complete compress."
}

function BackupKeepMonth($conf)
{
    if([Datetime]::Today.Day -ne 1)
    {
        return
    }

    $BACKUP_DIR = $INI["BACKUP_DIR"]
    $BACKUP_ZIP_PATH = $INI["BACKUP_ZIP_PATH"]

    $backup_name2 = "month" + ([Datetime]::Today.ToString("yyyyMM")) + ".zip"
    $zipPath2 = Join-Path $BACKUP_DIR $backup_name2

    if (( Test-Path $zipPath2)) {
        del $zipPath2
    }

    copy $BACKUP_ZIP_PATH $zipPath2
}

function Main()
{
    $Error.Clear()

    $SCRIPT_NAME = & { $MyInvocation.ScriptName }
    $BASE_DIR = Split-Path -Parent $SCRIPT_NAME
    $NOW_KEY = [DateTime]::Now.ToString("yyyyMMdd_HHmmss");

    $INI_PATH = $SCRIPT_NAME -replace (".ps1", ".ini")

    if(!(Test-Path $INI_PATH))
    {
        Write-Output "Error: Invalid INI_PATH $INI_PATH"
        Return 1
    }

    $INI = LoadIni $INI_PATH

    if($INI["BACKUP_DIR"] -eq $Null)
    {
        $INI["BACKUP_DIR"] = $BASE_DIR
    }

    if($INI["BACKUP_WEBSITE"] -eq $Null)
    {
        $INI["BACKUP_WEBSITE"] = "1"
    }

    if($INI["BACKUP_WEBSITE_DIR"] -eq $Null)
    {
        $INI["BACKUP_WEBSITE_DIR"] = "C:\inetpub\wwwroot"
    }

    $BACKUP_DIR = $INI["BACKUP_DIR"]
    $BACKUP_KEY = $INI["BACKUP_KEY"]
    $LOG_DIR = $INI["LOG_DIR"]
    $BACKUP_TARGET_DIR = $INI["BACKUP_TARGET_DIR"]
    $BACKUP_WEBSITE = $INI["BACKUP_WEBSITE"]
    $BACKUP_DATABASE = $INI["BACKUP_DATABASE"]

    if (!(Test-Path $BACKUP_DIR -PathType Container))
    {
        Write-Output "Error: Invalid BACKUP_DIR $BACKUP_DIR"
        Return 1
    }

    if($BACKUP_KEY -eq $null)
    {
        $BACKUP_KEY = $NOW_KEY
        $INI["BACKUP_KEY"] = $BACKUP_KEY
    }

    if($INI["BACKUP_ROTATE_WEEK"] -eq "1")
    {
        $BACKUP_KEY = "week" + [int]([Datetime]::Now.DayOfWeek)
        $INI["BACKUP_KEY"] = $BACKUP_KEY
    }

    if($BACKUP_TARGET_DIR -eq $null)
    {
        $BACKUP_TARGET_DIR = (Join-Path $BACKUP_DIR $BACKUP_KEY).ToString()
        $INI["BACKUP_TARGET_DIR"] = $BACKUP_TARGET_DIR
    }

    if($LOG_DIR -eq $null)
    {
        $LOG_DIR = Join-Path $BACKUP_DIR "log"
        $INI["LOG_DIR"] = $LOG_DIR
    }

    if($INI["BACKUP_DATABASE_LIST"] -eq $null)
    {
        $INI["BACKUP_DATABASE_LIST"] = "%BACKUP_SITE%Sitecore_Core,%BACKUP_SITE%Sitecore_Master,%BACKUP_SITE%Sitecore_Web"
    }

    $INI["BACKUP_ZIP_PATH"] = Join-Path $BACKUP_DIR "$BACKUP_KEY.zip"

    if (!( Test-Path $LOG_DIR))
    {
        mkdir $LOG_DIR | Out-Null
    }

    $log_path = Join-Path $LOG_DIR "backup${NOW_KEY}.log"

    start-transcript $log_path

    $ErrorActionPreference = "Stop"

    try
    {
        Write-Output "start backup. BACKUP_TARGET_DIR=$BACKUP_TARGET_DIR"

        if($INI["BACKUP_ROTATE_WEEK"] -eq "1" -and (Test-Path $BACKUP_TARGET_DIR))
        {
            rmdir -Force -Recurse $BACKUP_TARGET_DIR
        }

        if (!( Test-Path $BACKUP_TARGET_DIR)) {
            mkdir $BACKUP_TARGET_DIR | Out-Null
        }

        if($BACKUP_WEBSITE -eq "1")
        {
            BackupWebsite $INI
        }

        if($BACKUP_DATABASE -eq "1")
        {
            BackupDatabase $INI
        }
    }
    catch
    {
        Write-Output "Error: Backup failed."
        Write-Output $Error

        stop-transcript

        Return 1
    }

    stop-transcript

    $log_path2 = Join-Path $BACKUP_TARGET_DIR "backup.log"
    copy $log_path $log_path2

    start-transcript $log_path -append

    try
    {
        if($INI["BACKUP_COMPRESS_ZIP"] -eq "1")
        {
            CompressZip $INI

            if($INI["BACKUP_KEEP_MONTH"] -eq "1")
            {
                BackupKeepMonth $INI
            }
        }
    }
    catch
    {
        Write-Output "Error: Backup failed."
        Write-Output $Error

        stop-transcript

        Return 1
    }

    stop-transcript
}

Main

