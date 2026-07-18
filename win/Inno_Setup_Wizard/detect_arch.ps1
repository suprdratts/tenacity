param(
    [Parameter(Mandatory = $true)] [string] $ExePath,
    [Parameter(Mandatory = $true)] [string] $OutFile
)

# Read the PE Machine field and classify the target as x64 or x86.
$bytes    = [IO.File]::ReadAllBytes($ExePath)
$peOffset = [BitConverter]::ToInt32($bytes, 60)
$machine  = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
$arch = if ($machine -eq 0x8664 -or $machine -eq 0xAA64) { 'x64' } else { 'x86' }

[IO.File]::WriteAllText($OutFile, $arch)
