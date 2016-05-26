################################################################################

## AWS-CreateSnapshot.conf.ps1

# $AWS_REGION = "ap-northeast-1"
# $AWS_CREDENTIAL = "testawscred"

# $TARGET_VOLUME_LIST = @("vol-test1", "VOLUMENAME_TEST2")
# $SNAPSHOT_DESCRIPTION = "TEST1"

# Set-AWSCredentials -AccessKey "" -SecretKey "" -StoreAs $AWS_CREDENTIAL

# $SCRIPT_BEFORE = $MyInvocation.MyCommand.Path + "\..\AWS-CreateSnapshot.before.conf.ps1"
# $SCRIPT_AFTER = $MyInvocation.MyCommand.Path + "\..\AWS-CreateSnapshot.after.conf.ps1"
# $SCRIPT_LOG = $MyInvocation.MyCommand.Path + "\..\AWS-CreateSnapshot.log"

################################################################################

import-module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

$SCRIPT_LOG = $MyInvocation.MyCommand.Path + "\..\AWS-CreateSnapshot.log"

$TODAY = [DateTime]::Now.ToString("yyyyMMdd");

$CONF_PATH = ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, ".conf.ps1"))
if ( Test-Path $CONF_PATH )
{
	. $CONF_PATH
}

if($SCRIPT_LOG -ne $null)
{
	start-transcript $SCRIPT_LOG
}

echo ("start. region=" + $AWS_REGION + " profile=" + $AWS_CREDENTIAL)

Initialize-AWSDefaults -ProfileName $AWS_CREDENTIAL
Initialize-AWSDefaults -Region $AWS_REGION

if($SCRIPT_BEFORE -ne $null)
{
	. $SCRIPT_BEFORE
}

$volumes = Get-EC2Volume

$volumes = $volumes | Where-Object { $TARGET_VOLUME_LIST -contains $_.VolumeId -or ( $_.Tags.Key -eq "Name" -and $TARGET_VOLUME_LIST -contains ( $_.Tags | Where-Object { $_.Key -eq "Name" } ).Value ) }

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

	if($volumeTag -ne "")
	{
		$tag = New-Object Amazon.EC2.Model.Tag
		$tag.Key = "Name"
		$tag.Value = $volumeTag + " " + $TODAY

		echo ("Set snapshot tag:" + $snapshot.SnapshotId + " " + $tag.Value)
		New-EC2Tag -Resource $snapshot.SnapshotId -Tag $tag
	}
}

echo ("wait...")

while($snapshots.Length -gt 0)
{
	echo ("check...")
	$completeCount = 0
	foreach($snapshot in $snapshots)
	{
	    $snapshot2 = Get-EC2Snapshot -SnapshotId $snapshot.SnapshotId
		if( $snapshot2.Length -gt 0 -and $snapshot2[0].State -eq "completed" )
		{
			$completeCount ++
		}
	}
	echo ("complete count=" + $completeCount)
	if($completeCount -eq $snapshots.Length)
	{
		break
	}
	Start-Sleep -s 60
}

echo ("complete. region=" + $AWS_REGION + " profile=" + $AWS_CREDENTIAL)

if($SCRIPT_LOG -ne $null)
{
	stop-transcript
}

if($SCRIPT_AFTER -ne $null)
{
	. $SCRIPT_AFTER
}

