## base64.ps1 "Hello world"
## base64.ps1 -decode "SGVsbG8gd29ybGQ="

Param (
    [parameter(mandatory=$false)][switch]$decode,
    [parameter(mandatory=$false)][switch]$file,
    [parameter(mandatory=$true)][string]$text
)

if($text -eq "")
{
	echo "Help:"
	echo "  base64.ps1 ""UTF-8 text"" "
	echo "  base64.ps1 -decode ""base64 encoded text"" "
	exit -1
}

if($file)
{
	$text = [System.IO.File]::ReadAllText($text)
}

if($decode)
{
	$buffer = [System.Convert]::FromBase64String($text)
	$result = [System.Text.Encoding]::UTF8.GetString($buffer)
	echo ("Decode:`n" + $result)
}
else{
	$buffer = [System.Text.Encoding]::UTF8.GetBytes($text)
	$result = [System.Convert]::ToBase64String($buffer)
	echo ("Encode:`n" + $result)
}

#pause
