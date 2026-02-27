$recreateFile = "scripts/recreate_project.tcl"

$text = Get-Content $recreateFile -Raw

# Fix origin_dir
$text = $text -replace 'set origin_dir "\."', 'set origin_dir [file normalize [file dirname [info script]]]'
$text = $text -replace 'set origin_dir \."', 'set origin_dir [file normalize [file dirname [info script]]]'

# Fix project creation path
$text = $text -replace '\./\$\{_xil_proj_name_\}', '.'

Set-Content $recreateFile $text

Write-Host "Vivado recreate script fixed."