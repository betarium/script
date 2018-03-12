#############################################
# iis_log_backup.ini.ps1

$TARGET_FOLDER = "C:\inetpub\logs\LogFiles"

$BACKUP_FOLDER = "C:\backup"

$BACKUP_BEFORE_MONTH = 2

#############################################

Add-Type -AssemblyName System.IO.Compression.FileSystem

$LOG_PATH = ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, ".log"))

$INI_PATH = ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, ".ini.ps1"))

if(Test-Path $INI_PATH)
{
    . $INI_PATH
}

[int]$BACKUP_BEFORE_MONTH = $BACKUP_BEFORE_MONTH


#############################################

start-transcript $LOG_PATH | Out-null

if(-Not (Test-Path $BACKUP_FOLDER))
{
    Write-Output("Error: Backup folder not found.")
    exit -1
}

Write-Output("`n" + "start: " + $MyInvocation.MyCommand.Path + "`n")

$base_date = [DateTime]::Today

$begin_date = $base_date.AddMonths(-$BACKUP_BEFORE_MONTH).AddDays(1 - $base_date.Day)
$end_date = $begin_date.AddMonths(1).AddDays(-1)
$month = $begin_date.ToString("yyyy-MM")

Write-Output("--------------------")
Write-Output("Month:" + $month)
Write-Output("Target:" + $TARGET_FOLDER)
Write-Output("Backup:" + $BACKUP_FOLDER)
Write-Output("--------------------")

#############################################

$folderList = Get-ChildItem $TARGET_FOLDER

foreach($folder in $folderList)
{
    $source_folder = Join-Path $TARGET_FOLDER $folder.Name
    $dest_folder = Join-Path $BACKUP_FOLDER ($folder.Name + "_" + $month)
    $dest_file = $dest_folder + ".zip"

    Write-Output("Source:" + $source_folder)
    #Write-Output("Dest:" + $dest_folder)

    if(Test-Path $dest_file) {
        Write-Output("Error: Zip file already exists. path=" + $dest_file)
        continue
    }

    if(!(Test-Path $dest_folder)) {
        mkdir $dest_folder | Out-Null
    }

    $files = Get-ChildItem -Path $source_folder -Filter "*.log"
    if($files -eq $null)
    {
        Write-Output("Error: Directory access failed.")
        continue
    }
    foreach($file in $files)
    {
        #Write-Output("  Check: " + $file.Name)
        $file_ymd = $file.Name.Substring(4, 6)
        $file_date = [DateTime]::ParseExact($file_ymd, "yyMMdd", $null)

        if($file_date -ge $begin_date -and $file_date -le $end_date)
        {
            Write-Output("  Move file:" + $file.Name)
            move (Join-Path $source_folder $file.Name) -Dest $dest_folder
        }
    }

    if((Get-ChildItem $dest_folder).Count -eq 0)
    {
        Write-Output("Skip no file.")
        rmdir $dest_folder
        continue;
    }

    Write-Output("zip:" + $dest_file)

    [System.IO.Compression.ZipFile]::CreateFromDirectory($dest_folder, $dest_file)

    if(!(Test-Path $dest_file)) {
        Write-Output("Error: Zip compress failed.")
        exit 1
        return
    }

    Write-Output("rmdir:" + $dest_folder)

    $files = Get-ChildItem $dest_folder -Filter "*.log"
    foreach($file in $files)
    {
        $files.Delete();
    }

    if((Get-ChildItem $dest_folder).Count -eq 0)
    {
        rmdir $dest_folder
    }
}


#############################################

Write-Output("`n" + "Complete: " + $MyInvocation.MyCommand.Path + "`n")

stop-transcript

#pause
