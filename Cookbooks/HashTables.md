# HashTables
A PowerShell 5 cookbook about hash tables.

## Convert

Collect a pipeline of objects as a `HashTable`:
```powershell
function ConvertTo-HashTable([ScriptBlock]$GetKey, [ScriptBlock]$GetValue) {
    <# Use in a pipeline.  $GetKey and $GetValue should each be filter-like. #>
    $HashTable = @{ }
    foreach ($Object in $Input) {
        $Key = $Object | ForEach-Object $GetKey
        $Value = $Object | ForEach-Object $GetValue
        $HashTable[$Key] = $Value
    }
    return $HashTable
}
```