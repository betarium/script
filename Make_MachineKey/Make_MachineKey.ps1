# https://msdn.microsoft.com/ja-jp/library/w8h3skw9(v=vs.80).aspx
# https://support.microsoft.com/ja-jp/kb/312906

$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

$buff = New-Object byte[] -ArgumentList 64
$rng.GetBytes($buff)
$hexString = $buff | ForEach-Object{ [String]::Format("{0:X2}", $_) }
$validationKey = $hexString -join ""

$buff = New-Object byte[] -ArgumentList 24
$rng.GetBytes($buff)
$hexString = $buff | ForEach-Object{ [String]::Format("{0:X2}", $_) }
$decryptionKey = $hexString -join ""

echo "<machineKey validationKey=""$validationKey"" decryptionKey=""$decryptionKey"" validation=""SHA1"" />"

[Console]::ReadKey() | Out-Null

