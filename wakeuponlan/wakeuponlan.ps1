Param (
    [Parameter(Mandatory=$true)][string]$mac,
    [Parameter(Mandatory=$false)][int]$port = 9
)

$packet = New-Object 'System.Collections.Generic.List[string]'

0..5 | foreach { $packet.Add("FF") }

$mac2 = $mac.Split('-')
0..15 | foreach { $packet.AddRange($mac2) }

$data = New-Object 'System.Collections.Generic.List[byte]'
$packet | foreach { $data.Add([Byte]::Parse($_, [System.Globalization.NumberStyles]::HexNumber)) }

$udp = New-Object System.Net.Sockets.UdpClient(0)
$ipendp = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Broadcast, $port)
$result = $udp.Send($data.ToArray(), $data.Count, $ipendp)

