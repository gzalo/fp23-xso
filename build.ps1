nasm xso.asm -fbin -o xso.com
ndisasm -o100h xso.com > xso.txt
$file = 'xso.com'
Write-Host((Get-Item $file).length)
Write-Host(256-(Get-Item $file).length)
& "C:\Program Files (x86)\DOSBox-0.74-3\DosBox.exe" xso.com
