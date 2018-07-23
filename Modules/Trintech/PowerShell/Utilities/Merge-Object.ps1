<#
#>
function Merge-Object
{
    [CmdletBinding(PositionalBinding=$false)]
    param
    (
        [Parameter(Position=1)]
        [String]
        $MergedObjectType = 'PSCustomObject',

        [Parameter()]
        $ValueIfNone = $null,

        [Parameter(ValueFromPipeline=$true)]
        $InputObject
    )

    if ($Input.Count -eq 0) {
        return $ValueIfNone
    }

    $Merged = @{ }
    foreach ($Object in $Input) {
        foreach ($Property in $Object.PSObject.Properties) {
            $Merged.Remove($Property.Name)
            $Merged.Add($Property.Name, $Property.Value)
        }
    }
    return New-Object $MergedObjectType -Property $Merged
}