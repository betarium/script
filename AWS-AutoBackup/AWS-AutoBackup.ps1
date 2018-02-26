################################################################################

$AWS_REGION = "ap-northeast-1"

$AWS_CREDENTIAL = "aws-auto-backup-credential"

$BACKUP_NAME = "AutoBackup"

$BACKUP_CLEANUP_DAY = 7

$SNAPSHOT_DESCRIPTION = "AutoBackup"

# $TARGET_VOLUME_LIST = @("MY_VOLUME")

# $AWS_ACCESS_KEY = ""
# $AWS_SECRET_KEY = ""

# Set-AWSCredentials -AccessKey $AWS_ACCESS_KEY -SecretKey $AWS_SECRET_KEY -StoreAs $AWS_CREDENTIAL

################################################################################

import-module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

$TODAY = [DateTime]::Now.ToString("yyyyMMdd");

$SCRIPT_LOG = ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, "." + [DateTime]::Now.ToString("yyyyMM") +  ".log"))

$CONF_PATH = ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, ".conf.ps1"))
if ( Test-Path $CONF_PATH )
{
	. $CONF_PATH
}

start-transcript -Append -Path $SCRIPT_LOG

echo ("start. region=" + $AWS_REGION + " profile=" + $AWS_CREDENTIAL)

if ($AWS_CREDENTIAL -ne $null -and $AWS_CREDENTIAL -ne "")
{
    Initialize-AWSDefaults -ProfileName $AWS_CREDENTIAL -Region $AWS_REGION
}

if($SCRIPT_BEFORE -ne $null)
{
	. $SCRIPT_BEFORE
}

$volumes = Get-EC2Volume | Where-Object { $TARGET_VOLUME_LIST -contains $_.VolumeId -or $TARGET_VOLUME_LIST -contains ( $_.Tags | Where-Object { $_.Key -eq "Name" } ).Value }

$snapshots = @()

foreach($volume in $volumes)
{
	$volumeTag = ""
	if($volume.Tags.Key -eq "Name")
	{
		$volumeTag = ($volume.Tags | Where-Object { $_.Key -eq "Name" }).Value
	}

	echo ("Create snapshot:" + $volume.VolumeId + " " + $volumeTag)
	$snapshot = new-ec2snapshot -volumeid $volume.VolumeId -Description $SNAPSHOT_DESCRIPTION
	if($snapshot -eq $null)
	{
		echo ("Create snapshot failed.")
		break
	}
	$snapshots += $snapshot

	$tag = New-Object Amazon.EC2.Model.Tag
	$tag.Key = "Name"
	if($volumeTag -eq $null)
	{
		$volumeTag = $volume.VolumeId
	}
	$tag.Value = $volumeTag + " " + $TODAY

	New-EC2Tag -Resource $snapshot.SnapshotId -Tag $tag

	$tag = New-Object Amazon.EC2.Model.Tag
	$tag.Key = "AutoBackup"
	$tag.Value = $BACKUP_NAME

	New-EC2Tag -Resource $snapshot.SnapshotId -Tag $tag
}

echo ("wait...")

while($snapshots.Length -gt 0)
{
	#echo ("check...")
	$completeCount = 0
	foreach($snapshot in $snapshots)
	{
	    $snapshot2 = Get-EC2Snapshot -SnapshotId $snapshot.SnapshotId
		if( $snapshot2.Length -gt 0 -and $snapshot2[0].State -eq "completed" )
		{
			$completeCount ++
		}
	}
	#echo ("complete count=" + $completeCount)
	if($completeCount -eq $snapshots.Length)
	{
		break
	}
	Start-Sleep -s 60
}

if($BACKUP_CLEANUP_DAY -gt 0)
{
	echo ("cleanup snapshot...")

	$filter = New-Object Amazon.EC2.Model.Filter
	$filter.Name = 'tag:AutoBackup'
	$filter.Value = $BACKUP_NAME

	$snapshotList = Get-EC2Snapshot -Filter $filter

	$filterDate = (Get-Date).AddDays(-$BACKUP_CLEANUP_DAY)
	foreach($snapshot in $snapshotList)
	{
		$startTime = Get-Date -Date $snapshot.StartTime
		if($startTime -le $filterDate)
		{
			echo ("remove snap shot. id=" + $snapshot.SnapshotId + " date=" + $snapshot.StartTime)
			Remove-EC2Snapshot $snapshot.SnapshotId -Force
		}
	}
}

echo ("complete. region=" + $AWS_REGION + " profile=" + $AWS_CREDENTIAL)

stop-transcript

if($SCRIPT_AFTER -ne $null)
{
	. $SCRIPT_AFTER
}

