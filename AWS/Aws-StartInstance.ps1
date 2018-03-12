$parameterArgs = $Args[0]

$CONF_PATH = ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, ".conf.ps1"))

if(Test-Path $CONF_PATH)
{
    . $CONF_PATH
}

$SCRIPT_LOG = ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, [DateTime]::Now.ToString("yyyyMM") + ".log"))

start-transcript $SCRIPT_LOG

#$INSTANCE_STATUS = Get-EC2InstanceStatus -StoredCredentials $CREDENTIALS -Region $REGION -InstanceId $INSTANCE_ID | ConvertTo-Json

if( $parameterArgs -eq "--start" -or $parameterArgs -eq $null ){
	echo ("Start " + $INSTANCE_ID)
	Start-EC2Instance -StoredCredentials $CREDENTIALS -Region $REGION -Instance $INSTANCE_ID
} elseif( $parameterArgs -eq "--stop" ){
	echo ("Stop " + $INSTANCE_ID)
	Stop-EC2Instance -StoredCredentials $CREDENTIALS -Region $REGION -Instance $INSTANCE_ID
}

$status = Get-EC2InstanceStatus -StoredCredentials $CREDENTIALS -Region $REGION -InstanceId $INSTANCE_ID | ConvertTo-Json

echo $status

sleep 10

#pause
