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

echo "0: Create Self Sign`n1: Create CA Cert`n2: Create Server Cert"
$result = [Console]::ReadLine()
if($result -eq "")
{
	$result = "0"
}

echo ("Input CA name. (" + $INI["CA_NAME"] + ")")
$CA_NAME = [Console]::ReadLine()
if($CA_NAME -eq "")
{
	$CA_NAME = $INI["CA_NAME"]
}

echo "CA name=${CA_NAME}"

$TARGET_DIR = $BASE_PATH + "\" + ${CA_NAME}
$CONF_FILE = $TARGET_DIR + "\openssl.cnf.txt"
$Env:RANDFILE = ($TARGET_DIR + "\.rnd")

if($result -eq "0")
{
	#Remove-Item -path $TARGET_DIR -recurse -force
	New-Item -itemType Directory $TARGET_DIR | Out-Null
	Set-Location -Path $TARGET_DIR

	copy "..\openssl.cnf" "$CONF_FILE"
	mkdir newcerts

	$confdata = $(Get-Content $CONF_FILE)
	$confdata = $confdata -replace "dir		= /usr/ssl",("dir		= " + ($TARGET_DIR -replace "\\","/"))
	#$confdata | Out-File $CONF_FILE -Encoding UTF8
	$confdata | Out-File $CONF_FILE -Encoding ASCII

	#New-Item -itemType Directory ($TARGET_DIR + "\demoCA\newcerts") | Out-Null
	Out-File index.txt
	echo "00" | Out-File -Encoding ascii serial

	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "genrsa -out ""${CA_NAME}.key"" 2048"
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "req -new -key ""${CA_NAME}.key"" -out ""${CA_NAME}.csr"" -config ""${CONF_FILE}"" -subj ""/C=JP/ST=Tokyo/L=System/O=System/OU=System/CN=${CA_NAME}"" "
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "ca -selfsign -batch -days 3650 -in ""${CA_NAME}.csr"" -config ""${CONF_FILE}"" -keyfile ""${CA_NAME}.key"" -out ""${CA_NAME}.crt"""
	#Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "x509 -days 3650 -in ""${CA_NAME}.csr"" -req -signkey ""${CA_NAME}.key"" -out ""${CA_NAME}.crt"""
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "pkcs12 -export -name ""${CA_NAME}"" -password ""pass:"" -in ""${CA_NAME}.crt"" -inkey ""${CA_NAME}.key"" -out ""${CA_NAME}.pfx"" "
}
if($result -eq "1")
{
	#Remove-Item -path $TARGET_DIR -recurse -force
	New-Item -itemType Directory $TARGET_DIR | Out-Null
	Set-Location -Path $TARGET_DIR

	copy "C:\Program Files\Git\usr\ssl\openssl.cnf" "$CONF_FILE"

	$confdata = $(Get-Content $CONF_FILE)
	$confdata = $confdata -replace "dir		= /usr/ssl",("dir		= " + ($TARGET_DIR -replace "\\","/"))
	#$confdata | Out-File $CONF_FILE -Encoding UTF8
	$confdata | Out-File $CONF_FILE -Encoding ASCII

	#New-Item -itemType Directory ($TARGET_DIR + "\demoCA\newcerts") | Out-Null
	Out-File index.txt
	echo "00" | Out-File -Encoding ascii serial

	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "genrsa -out ""${CA_NAME}.key"" 2048"
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "req -new -key ""${CA_NAME}.key"" -out ""${CA_NAME}.csr"" -config ""${CONF_FILE}"" -subj ""/C=JP/ST=Tokyo/L=System/O=System/OU=System/CN=${CA_NAME}"" "
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "x509 -days 3650 -in ""${CA_NAME}.csr"" -req -signkey ""${CA_NAME}.key"" -out ""${CA_NAME}.crt"""
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "pkcs12 -export -name ""${CA_NAME}"" -password ""pass:"" -in ""${CA_NAME}.crt"" -inkey ""${CA_NAME}.key"" -out ""${CA_NAME}.pfx"" "
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
	$FILE_NAME = $SERVER_NAME
	$FILE_NAME = $FILE_NAME -replace "\*", "~"

	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "genrsa -out ""${FILE_NAME}.key"" 2048"
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "req -new -key ""${FILE_NAME}.key"" -out ""${FILE_NAME}.csr"" -config ""${CONF_FILE}"" -subj ""/C=JP/ST=Tokyo/L=System/O=System/OU=System/CN=${SERVER_NAME}"" "
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "ca -batch -days 3650 -config ""${CONF_FILE}"" -cert ""${CA_NAME}.crt"" -key """" -keyfile ""${CA_NAME}.key"" -in ""${FILE_NAME}.csr"" -outdir ""${TARGET_DIR}"" -out ""${FILE_NAME}.crt"" "
	Start-Process -Wait -NoNewWindow -FilePath openssl -ArgumentList "pkcs12 -export -name ""${SERVER_NAME}"" -password ""pass:"" -in ""${FILE_NAME}.crt"" -inkey ""${FILE_NAME}.key"" -out ""${FILE_NAME}.pfx"" "
}

echo "Complete."
[Console]::ReadKey() | Out-Null


