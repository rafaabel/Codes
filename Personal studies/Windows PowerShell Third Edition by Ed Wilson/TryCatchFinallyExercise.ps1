param (
    [Parameter(Mandatory = $true)]
    $Object
)

"Beginning test..."

try {
    "`tAttempting to create object $object"
    New-Object $Object
}
catch {
    [System.Exception]
    "`tUnable to create $object"
}
finally {
    "Reached the end of the script"
}
