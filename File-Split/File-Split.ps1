param($path,$join=$false,$splitSize=1024*1024*1024)

if(-not $join)
{
    echo ("Split Source: " + $path)
    echo ("Split Size: " + $splitSize)
    $stream = New-Object System.IO.FileStream($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    $buffer = New-Object byte[] -ArgumentList ($splitSize)
    $fileCount = 0
    while ($true)
    {
        $size = $stream.Read($buffer, 0, $buffer.Length)
        if ($size -le 0)
        {
            break
        }
        $fileCount++;
        $filePrefix = "{0:0000}" -F $fileCount
        $destPath = $path + "." + $filePrefix + ".split"
        $destStream = New-Object System.IO.FileStream($destPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
        $destStream.Write($buffer, 0, $size);
        $destStream.Close();
        echo ("Dest: " + $destPath)
    }
    $stream.Close();
}
else
{
    echo ("Join Source: " + $path)
    $fileCount = 0;
    $fileName=[System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetFileNameWithoutExtension($path))
    $destPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($path), $fileName)
    $destStream = New-Object System.IO.FileStream($destPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
    while ($true)
    {
        $fileCount++;
        $filePrefix = "{0:0000}" -F $fileCount
        $sourcePath = $destPath + "." + $filePrefix + ".split";
        if (-not [System.IO.File]::Exists($sourcePath))
        {
            break;
        }
        echo ("Source: " + $sourcePath)
        $stream = New-Object System.IO.FileStream($sourcePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $buffer = New-Object byte[] -ArgumentList ($stream.Length)
        $size = $stream.Read($buffer, 0, $buffer.Length);
        $stream.Close();

        $destStream.Write($buffer, 0, $size);
    }
    $destStream.Close();
    echo ("Dest: " + $destPath);
}

echo ("Complete.")
