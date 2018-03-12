Param (
    [string]$Message = "",
    [string]$Username = "",
    [string]$WebhookUrl = ""
)

$INI_PATH = ([System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, ".conf.ps1"))

if($Username -eq "")
{
    $Username = "bot:$Env:COMPUTERNAME"
}

if(Test-Path $INI_PATH)
{
    . $INI_PATH
}

$data = @{
    text = $Message;
    username = $Username;
}

$json = ConvertTo-Json($data)
$body = [System.Text.Encoding]::UTF8.GetBytes($json)

Invoke-RestMethod -Uri "$WebhookUrl" -Method Post -Body $body

#pause
