Param (
    [parameter(mandatory=$true)][string]$path
)

if($path -eq "")
{
    echo "Help:"
    echo "  md5.ps1 <path>"
    exit -1
}

$pathList = @()

if( Test-Path $path -PathType container )
{
    $children = [System.IO.Directory]::GetFiles($path)
    foreach($child in $children)
    {
        $pathList += $child
    }
}
else
{
    $pathList += $path
}

foreach($file in $pathList)
{
    $provider = [System.Security.Cryptography.MD5CryptoServiceProvider]::Create()

    $stream = New-Object System.IO.FileStream($file, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)

    $buf = New-Object byte[]  -ArgumentList $stream.Length
    $len = $stream.Read($buf, 0, $buf.Length)
    $stream.Close()

    $dummy = $provider.TransformFinalBlock($buf, 0, $len)

    $hash = $provider.Hash

    $hashStr = ""

    foreach($hashPart in $hash)
    {
        $hashStr += [String]::Format("{0:X2}", $hashPart)
    }

    $name = [System.IO.Path]::GetFileName($file)

    echo ($hashStr + "`t" + $name + "`t")
}

