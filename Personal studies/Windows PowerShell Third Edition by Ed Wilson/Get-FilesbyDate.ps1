Function Get-FilesbyData
{
Param (
[string[]]$fileTypes,
[int]$month,
[int]$year,
[string[]]$path)

Get-ChildItem -Path $path -Include $fileTypes -Recurse | Where-Object {
    $_.LastWriteTime.Month -eq $month -AND $_.LastWriteTime.Year -eq $year
}

}
