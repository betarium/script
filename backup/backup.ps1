# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

[CmdletBinding(SupportsShouldProcess = $true)]
Param()

########################################

$SCRIPT_NAME = &{ $MyInvocation.ScriptName }
$SCRIPT_DIR = Split-Path -Parent $SCRIPT_NAME
$SCRIPT_CONF_PATH = ([System.IO.Path]::ChangeExtension($SCRIPT_NAME, ".conf.ps1"))

########################################

$BACKUP_DIR = $null
$BACKUP_DATE = [DateTime]::Now.ToString("yyyyMMdd_HHmmss")

$BACKUP_LOG_DIR = $Null
$BACKUP_LOG_NAME = Split-Path -Leaf $SCRIPT_NAME
$BACKUP_LOG_NAME = ([System.IO.Path]::ChangeExtension($BACKUP_LOG_NAME, ".log"))
$BACKUP_LOG_PATH = $Null

$BACKUP_CURRENT_DIR = $null

$BACKUP_LIST = @()

#$VerbosePreference = "Continue"
#$DebugPreference = "Continue"

########################################

if(Test-Path $SCRIPT_CONF_PATH)
{
    . $SCRIPT_CONF_PATH
}

if($BACKUP_DIR -eq $null)
{
    $BACKUP_DIR = $SCRIPT_DIR
    $BACKUP_DIR = Join-Path $BACKUP_DIR "backup"
}

if($BACKUP_CURRENT_DIR -eq $null)
{
    $BACKUP_CURRENT_DIR = $BACKUP_DIR
    $BACKUP_CURRENT_DIR = Join-Path $BACKUP_CURRENT_DIR $BACKUP_DATE
}

if($BACKUP_LOG_DIR -eq $null)
{
    $BACKUP_LOG_DIR = $BACKUP_DIR
    if(Test-Path (Join-Path $BACKUP_DIR "~log"))
    {
        $BACKUP_LOG_DIR = Join-Path $BACKUP_DIR "~log"
    }
}

if($BACKUP_LOG_PATH -eq $null)
{
    $BACKUP_LOG_PATH = Join-Path $BACKUP_LOG_DIR $BACKUP_LOG_NAME
}

if($BACKUP_LIST.Length -eq 0)
{
    Write-Warning("BACKUP_LIST is empty.")
    exit 1
}

########################################

start-transcript $BACKUP_LOG_PATH | Write-Verbose

Write-Verbose("BACKUP_DIR: " + $BACKUP_CURRENT_DIR)

if(Test-Path $BACKUP_CURRENT_DIR -PathType container)
{
    if($PSCmdlet.ShouldProcess("rmdir: " + $BACKUP_CURRENT_DIR))
    {
        Write-Verbose("rmdir: " + $BACKUP_CURRENT_DIR)
        $dummy = rmdir -Recurse -Force $BACKUP_CURRENT_DIR
    }
}

if(-not (Test-Path $BACKUP_CURRENT_DIR -PathType container))
{
    if($PSCmdlet.ShouldProcess("mkdir: " + $BACKUP_CURRENT_DIR))
    {
        Write-Verbose("mkdir: " + $BACKUP_CURRENT_DIR)
        $dummy = mkdir $BACKUP_CURRENT_DIR
    }
}

########################################

Write-Verbose("start backup...")

foreach ($BackupPath in $BACKUP_LIST)
{
    Write-Debug("check: " + $BackupPath)

    $FileType = $null

    if(Test-Path $BackupPath -PathType leaf)
    {
        Write-Debug("file: " + $BackupPath)
        $FileType = "file"
    }
    elseif(Test-Path $BackupPath -PathType container)
    {
        Write-Debug("dir: " + $BackupPath)
        $FileType = "dir"
    }
    else
    {
        Write-Warning($BackupPath + " not found.")
        continue
    }

    $fileName = Split-Path -Leaf $BackupPath

    $BackupDestPath = Join-Path $BACKUP_CURRENT_DIR $fileName

    if($FileType -eq "file")
    {
        if($PSCmdlet.ShouldProcess("backup file: " + $BackupPath + " -> " + $BackupDestPath))
        {
            copy $BackupPath $BackupDestPath
            Write-Verbose("backup file: " + $BackupPath + " -> " + $BackupDestPath)
        }
    }
    elseif($FileType -eq "dir")
    {
        if($PSCmdlet.ShouldProcess("backup dir: " + $BackupPath + " -> " + $BackupDestPath))
        {
            xcopy /s $BackupPath ($BackupDestPath + "\") | Write-Verbose
            Write-Verbose("backup dir: " + $BackupPath + " -> " + $BackupDestPath)
        }
    }
}

Write-Verbose("complete backup.")

########################################

if($PSCmdlet.ShouldProcess("stop-transcript"))
{
    stop-transcript | Write-Verbose
    copy $BACKUP_LOG_PATH $BACKUP_CURRENT_DIR
}

