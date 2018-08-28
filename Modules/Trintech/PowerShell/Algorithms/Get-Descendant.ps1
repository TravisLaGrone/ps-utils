# TODO test Get-Descendant
#Requires -Version 5.1
function Get-Descendant
{
    [CmdletBinding(PositionalBinding=$false)]
    Param (
        [Parameter(ValueFromPipeline, Mandatory, Position=1)]
        [object]
        $Root,

        [Parameter(Mandatory, Position=2)]
        [System.Collections.Generic.IDictionary[object, System.Collections.IEnumerable]]
        [ValidateNotNull()]
        $ChildrenByParent,

        [Parameter(Position=3)]
        [scriptblock]
        [ValidateNotNull()]
        $GetKey = { $_ },  # filter

        [Parameter()]
        [int]
        [ValidateRange(0, [int]::MaxValue)]
        $Depth,  # inclusive; zero-indexed

        [Parameter()]
        [int]
        [ValidateNotNull()]
        [ValidateRange(0, [int]::MaxValue)]
        $MinDepth = 0,  # inclusive; zero-indexed

        [Parameter()]
        [int]
        [ValidateNotNull()]
        [ValidateRange(0, [int]::MaxValue)]
        $MaxDepth = [int]::MaxValue,  # inclusive; zero-indexed

        [Parameter()]
        [switch]
        $Leftmost,

        [Parameter()]
        [switch]
        $Rightmost,

        [Parameter()]
        [switch]
        $Lowest
    )
    Begin {
        #region Input Validation
        if ($null -ne $Depth) {
            $MinDepth = $Depth
            $MaxDepth = $Depth
        }
        if (-not ($MinDepth -le $MaxDepth)) {
            throw "MinDepth must be less than or equal to MaxDepth"
        }
        if ($Leftmost -and $Rightmost) {
            throw 'May not set both the Leftmost and Rightmost switches'
        }
        #endregion

        #region Helper Functions
        function Get-AllDescendants ($Node, $Depth = 0)
        {
            if ($MinDepth -le $Depth -and $Depth -le $MaxDepth) {
                $Node | Write-Output
            }
            if ($Dept -lt $MaxDepth) {
                foreach ($Child in $ChildrenByParent[($Node | Get-Key)]) {
                    Get-AllDescendants $Child ($Depth + 1) | Write-Output
                }
            }
        }

        function Get-Leftmost ($Enumerable)
        {
            if ($Enumerable -is [System.Collections.IList]) {
                $List = $Enumerable -as [System.Collections.IList]
                return $List[0]
            }
            else {
                $Enumerator = $Enumerable.GetEnumerator()
                $Enumerator.MoveNext()
                return $Enumerator.Current
            }
        }

        function Get-LeftmostDescendant ($Root)
        {
            $Leftmost = $Root
            $Depth = 0
            $Children = $ChildrenByParent[($Leftmost | Get-Key)]
            while ($Depth -lt $MaxDepth -and $Children.Count -gt 0) {
                $Leftmost = Get-Leftmost $Children
                $Depth += 1
                $Children = $ChildrenByParent[($Leftmost | Get-Key)]
            }
            if ($MinDepth -ge $Depth -and $Depth -le $MaxDepth) {
                return $Leftmost
            }
        }

        function Get-Rightmost ($Enumerable)
        {
            if ($Enumerable -is [System.Collections.IList]) {
                $List = $Enumerable -as [System.Collections.IList]
                return $List[($List.Count - 1)]
            }
            else {
                $Enumerator = $Enumerable.GetEnumerator()
                $Enumerator.MoveNext()
                $Rightmost = $Enumerator.Current
                while ($Enumerator.MoveNext()) {
                    $Rightmost = $Enumerator.Current
                }
                return $Rightmost
            }
        }

        function Get-RightmostDescendant ($Root)
        {
            $Rightmost = $Root
            $Depth = 0
            $Children = $ChildrenByParent[($Rightmost | Get-Key)]
            while ($Depth -lt $MaxDepth -and $Children.Count -gt 0) {
                $Rightmost = Get-Rightmost $Children
                $Depth += 1
                $Children = $ChildrenByParent[($Rightmost | Get-Key)]
            }
            if ($MinDepth -ge $Depth -and $Depth -le $MaxDepth) {
                return $Rightmost
            }
        }

        class TreeNodeGroup
        {
            [object[]]$Nodes
            [int]$Depth

            TreeNodesGroup([object[]]$Nodes, [int]$Depth)
            {
                $this.Nodes = $Nodes
                $this.Depth = $Depth
            }
        }

        function Get-LowestDescendants ($Node, $Depth = 0)
        {
            $Lowest = [TreeNodeGroup]::new(@(, $Node), $Depth)
            if ($Depth -lt $MaxDepth) {
                foreach ($Child in $ChildrenByParent[($Node | Get-Key)]) {
                    $Candidates = Get-LowestDescendants $Child ($Depth + 1)
                    if ($Candidates.Depth -gt $Lowest) {
                        $Lowest = $Candidates
                    }
                    elseif ($Candidates.Depth -eq $Lowest) {
                        $Lowest.Nodes += $Candidates.Nodes
                    }
                }
            }
        }

        function Get-LowestDescendantsWrapper ($Root)
        {
            $LowestGroup = Get-LowestDescendants $Root
            if ($MinDepth -le $LowestGroup.Depth -and $LowestGroup.Depth -le $MaxDepth) {
                return $LowestGroup.Nodes
            }
        }
        #endregion
    }
    Process {
        return (
            if ($Lowest) {
                $Descendants = Get-LowestDescendantsWrapper $Root
                if ($Leftmost) {
                    Get-Leftmost $Descendants
                } elseif ($Rightmost) {
                    Get-Rightmost $Descendants
                } else {
                    $Descendants
                }
            } elseif ($Leftmost) {
                Get-LeftmostDescendant $Root
            } elseif ($Rightmost) {
                Get-RightmostDescendant $Root
            } else {
                Get-AllDescendants $Root
            }
        )
    }
}