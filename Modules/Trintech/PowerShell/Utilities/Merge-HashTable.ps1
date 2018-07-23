<#
#>
function Merge-HashTable
{
    [CmdletBinding(PositionalBinding=$false)]
    param
    (
        [Parameter()]
        $ValueIfNone = $null,

        [Parameter(ValueFromPipeline=$true)]
        [HashTable]
        $InputObject
    )

    if ($Input.Count -eq 0) {
        return $ValueIfNone
    }

    $Merged = @{ }
    foreach ($HashTable in $Input) {
        foreach ($Item in $HashTable.GetEnumerator()) {
            $Merged.Remove($Item.Key)
            $Merged.Add($Item.Key, $Item.Value)
        }
    }
    return $Merged
}