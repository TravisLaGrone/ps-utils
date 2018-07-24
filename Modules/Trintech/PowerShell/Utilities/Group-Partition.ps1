<#
.SYNOPSIS
    Groups elements into partitions.
.PARAMETER EquivalenceFunction
    A delay-bind "end" function (not filter / "process" function) that returns
    whether all input elements are equal. It returns false if there exists any
    two distinct input elements that are not equal. Otherwise, returns true.
    Aliased as "Equals".
.PARAMETER NonCrossing
    Indicates that the input will be grouped into non-crossing partitions based
    on the input order. If three objects @(a, b, c) would otherwise be grouped
    into the cross partitions @(@(a, c), @(b)), then they will instead be grouped
    into the non-crossing partitions @(@(a), @(b), @(c)). If the input order is
    not meaningful, then this option is nonsensical.
.INPUTS
    Object
        The pipeline of objects to partition. Nullable. May be empty.
.OUTPUTS
    ArrayList<ArrayList<Object>>
        The partition of the input objects. Not null. May be empty.
.NOTES
    See https://docs.microsoft.com/en-us/dotnet/api/system.collections.arraylist
#>
function Group-Partition
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNull()]
        [ScriptBlock]
        [Alias('Equals')]
        $EquivalenceFunction = {
            $IsEmpty = -not $Input.MoveNext()
            if ($IsEmpty) {
                return $true
            }

            $First = $Input.Current
            while ($Input.MoveNext()) {
                $Next = $Input.Current
                if ($First -ne $Next) {
                    return $false
                }
            }
            return $true
        },

        [Parameter()]
        [Switch]
        $NonCrossing,

        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    $Partitions = New-Object System.Collections.ArrayList
    if ($NonCrossing) {
        #region Initialize Loop
        $Partition = New-Object System.Collections.ArrayList
        if ($Input.HasNext()) {
            $Partition.Add($Input.Current)
        }
        #endregion Initialize Loop

        #region Loop
        while ($Input.HasNext()) {
            $Current = $Input.Current
            if ($Current -ne $Partition[$Partition.Count - 1]) {
                $Partitions.Add($Partition)
                $Partition = New-Object System.Collections.ArrayList
            }
            $Partition.Add($Current)
        }
        #endregion Loop

        #region Finalize Loop
        if ($Partition.Count -gt 0) {
            $Partitions.Add($Partition)
        }
        #endregion Finalize Loop
    }
    else {
        #region Initialize Loop
        if ($Input.HasNext()) {
            $Partition = New-Object System.Collections.ArrayList
            $Partition.Add($Input.Current)
            $Partitions.Add($Partition)
        }
        #endregion Initialize Loop

        #region Loop
        while ($Input.HasNext()) {
            $Current = $Input.Current
            foreach ($Partition in $Partitions) {
                if ($Current -eq $Partition[0]) {
                    $Partition.Add($Current)
                    continue
                }
            }
            $Partition = New-Object System.Collections.ArrayList
            $Partition.Add($Current)
            $Partitions.Add($Partition)
        }
        #endregion Loop
    }
    return $Partitions
}