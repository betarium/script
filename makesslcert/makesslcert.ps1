$INI_PATH = $MyInvocation.MyCommand.Path + ".ini"
$BASE_PATH = $MyInvocation.MyCommand.Path

$BASE_PATH = Split-Path -Parent $BASE_PATH

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

$INI = LoadIni $INI_PATH

$Env:Path = $INI["OPENSSL_DIR"] + ";" + $Env:Path

echo "1: Create CA Cert`n2: Create Server Cert"
$result = [Console]::ReadLine()
if($result -eq "")
{
	$result = "1"
}

echo ("Input CA name. (" + $INI["CA_NAME"] + ")")
$CA_NAME = [Console]::ReadLine()
if($CA_NAME -eq "")
{
	$CA_NAME = $INI["CA_NAME"]
}

echo "CA name=${CA_NAME}"

$TARGET_DIR=$BASE_PATH + "\" + ${CA_NAME}
$Env:RANDFILE = ($TARGET_DIR + "\.rnd")

if($result -eq "1")
{
	#Remove-Item -path $TARGET_DIR -recurse -force
	New-Item -itemType Directory $TARGET_DIR | Out-Null
	Set-Location -Path $TARGET_DIR

	copy "C:\Program Files (x86)\Git\ssl\openssl.cnf" ($TARGET_DIR + "\openssl.cnf")

	New-Item -itemType Directory ($TARGET_DIR + "\demoCA\newcerts") | Out-Null
	Out-File demoCA\index.txt
	echo "00" | Out-File -Encoding ascii demoCA\serial

	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "genrsa -out ""${CA_NAME}.key"" 2048"
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "req -new -key ""${CA_NAME}.key"" -out ""${CA_NAME}.csr"" -config openssl.cnf -subj ""/C=JP/ST=Tokyo/L=System/O=System/OU=System/CN=${CA_NAME}"" "
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "x509 -days 3650 -in ""${CA_NAME}.csr"" -req -signkey ""${CA_NAME}.key"" -out ""${CA_NAME}.crt"""
}
if($result -eq "2")
{
	Set-Location -Path $TARGET_DIR

	echo ("Input server name. (" + $INI["SERVER_NAME"] + ")")
	$SERVER_NAME = [Console]::ReadLine()
	if($SERVER_NAME -eq "")
	{
		$SERVER_NAME = $INI["SERVER_NAME"]
	}

	echo "Server name=${SERVER_NAME}"

	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "genrsa -out ""${SERVER_NAME}.key"" 2048"
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "req -new -key ""${SERVER_NAME}.key"" -out ""${SERVER_NAME}.csr"" -config openssl.cnf -subj ""/C=JP/ST=Tokyo/L=System/O=System/OU=System/CN=${SERVER_NAME}"" "
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "ca -batch -days 3650 -config openssl.cnf -cert ""${CA_NAME}.crt"" -key """" -keyfile ""${CA_NAME}.key"" -in ""${SERVER_NAME}.csr"" -out ""${SERVER_NAME}.crt"" "
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "pkcs12 -export -name ""${SERVER_NAME}"" -password ""pass:password"" -in ""${SERVER_NAME}.crt"" -inkey ""${SERVER_NAME}.key"" -out ""${SERVER_NAME}.pfx"" "
}

echo "Complete."
[Console]::ReadKey() | Out-Null


