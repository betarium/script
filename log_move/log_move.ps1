Param (
    [string]$TargetFolder = ""
)

#############################################

$TARGET_FOLDER = "C:\inetpub\logs\LogFiles\W3SVC1"

$BACKUP_FOLDER = "C:\backup"

$BACKUP_BEFORE_MONTH = 1

#############################################

$LOG_PATH = ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, ".log"))

$INI_PATH = ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, ".ini.ps1"))

if(Test-Path $INI_PATH)
{
    . $INI_PATH
}

[int]$BACKUP_BEFORE_MONTH = $BACKUP_BEFORE_MONTH

if($TargetFolder -eq "")
{
    $TargetFolder = $TARGET_FOLDER
}

#############################################

start-transcript $LOG_PATH | Out-null

Write-Output("`n" + "start: " + $MyInvocation.MyCommand.Path + "`n")

$base_date = [DateTime]::Today

$begin_date = $base_date.AddMonths(-$BACKUP_BEFORE_MONTH).AddDays(1 - $base_date.Day)
$end_date = $begin_date.AddMonths(1).AddDays(-1)
$month = $begin_date.ToString("yyyy-MM")

$source_folder = $TargetFolder
$dest_folder = Join-Path $BACKUP_FOLDER $month
$dest_file = $dest_folder + ".zip"

Write-Output("Month:" + $month)

Write-Output("Source:" + $source_folder)
Write-Output("Dest:" + $dest_folder)

#############################################

if(Test-Path $dest_file) {
    Write-Output("error: zip file exists")
    #del $dest_file
    stop-transcript
    exit 2
    return
}

if(!(Test-Path $dest_folder)) {
    mkdir $dest_folder | Out-Null
}

$files = Get-ChildItem $source_folder

$fileCount = 0

foreach($file in $files)
{
    try
    {
        $file_ymd = $file.Name.Substring(4, 6)
        $file_date = [DateTime]::ParseExact($file_ymd, "yyMMdd", $null)

        if($file_date -ge $begin_date -and $file_date -le $end_date)
        {
            $fileCount++
            Write-Output("  file:" + $file.Name)
            move (Join-Path $source_folder $file.Name) -Dest $dest_folder
        }
    }
    catch
    {
        Write-Output($Error[0])
        continue
    }
}

#############################################

Write-Output("zip:" + $dest_file)

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($dest_folder, $dest_file)

if(!(Test-Path $dest_file)) {
    Write-Output("zip error")
    exit 1
    return
}

#############################################

Write-Output("rmdir:" + $dest_folder)

$files = Get-ChildItem $dest_folder
foreach($file in $files)
{
    $files.Delete();
}

rmdir $dest_folder

#############################################

Write-Output("`n" + "end: " + $MyInvocation.MyCommand.Path + "`n")

stop-transcript

#Write-Output("続行するには何かキーを押してください . . .")
#[Console]::ReadKey($true) | Out-Null
