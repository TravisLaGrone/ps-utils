<#
.SYNOPSIS
    Gets all descendant processes of the given process.
.PARAMETER RootId
    The process ID of the root process for which to get descendant processes.
    RootId defaults to $PID.
.PARAMETER MaxDepth
    The maximum tree depth of the descendant tree for which to get descendant
    processes.  MaxDepth is inclusive and zero-indexed.  MaxDepth must be non-null
    and non-negative.  MaxDepth defaults to [int]::MaxValue.
.PARAMETER RequireSameSessionId
    Whether to get only those descendants of RootId that have the same SessionId
    as the RootId process.  (i.e. only processes in the same session)
.PARAMETER ExcludeRootId
    Whether to exclude RootId from the output of this function.  (i.e. whether
    to output only *proper* descendants of RootId)  RootId is included by default.
.INPUTS
    System.UInt32
        RootId
.OUTPUTS
    System.UInt32
        The process ID of each descendant process of RootId, subject to other
        constraining parameters, if any.  No guarantees are made as to output order.
#>
function Get-DescendantProcess
{
    [CmdletBinding(PositionalBinding=$false)]
    Param (
        [Parameter(ValueFromPipeline, Position=1)]
        [UInt32]
        [ValidateNotNull()]
        $RootId = $PID,

        [Parameter(Position=2)]
        [int]
        [ValidateNotNull()]
        [ValidateRange(0, [int]::MaxValue)]  # non-negative
        $MaxDepth = [int]::MaxValue,  # inclusive; zero-indexed

        [Parameter()]
        [switch]
        $RequireSameSessionId,

        [Parameter()]
        [switch]
        $ExcludeRootId
    )
    Process {
        $Query = "SELECT ProcessId, ParentProcessId FROM Win32_Process"
        if ($RequireSameSessionId) {
            $Query += " WHERE SessionId = $((Get-Process -Id $RootId).SessionId)"
        }
        $ChildrenByParent = `
            Get-CimInstance -query $Query |
            Group-Object -Property ParentProcessId -AsHashTable

        function Get-Descendants ($Id = $RootId, $Depth = 0)
        {
            if ($Depth -lt $MaxDepth) {
                foreach ($DescendantId in $ChildrenByParent[$Id]) {
                    $DescendantId | Write-Output
                    Get-Descendants $DescendantId ($Depth + 1) | Write-Output
                }
            }
        }

        if (-not $ExcludeRootId) {
            $RootId | Write-Output
        }
        Get-Descendants | Write-Output
    }
}