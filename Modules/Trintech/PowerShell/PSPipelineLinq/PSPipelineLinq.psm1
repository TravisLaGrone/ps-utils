& "$PSScriptRoot\Add-SourceFiles.ps1"

$ExportFunctions = New-Object System.Collections.ArrayList
$ExportAliases = New-Object System.Collections.ArrayList


enum QueryType {
	Aggregate
	All
	Any
	Append
	AppendMany
	AsEnumerable
	Average
	Concat
	ConcatMany
	Contains
	ContainsAll
	ContainsAny
	Count
	DefaultIfEmpty
	Distinct
	ElementAt
	ElementAtOrDefault
	Except
	First
	FirstOrDefault
	GroupBy
	GroupJoin
	Intersect
	Join
	Last
	LastOrDefault
	Max
	Min
	OfType
	OrderBy
	OrderByDescending
	Prepend
	PrependMany
	Range
	Repeat
	Reverse
	Select
	SelectMany
	SequenceEqual
	Single
	SingleOrDefault
	Skip
	SkipLast
	SkipWhile
	Sum
	Take
	TakeLast
	TakeWhile
	ToArray
	ToDictionary
	ToHashSet
	ToList
	ToLookup
	Union
	Where_
	Zip
}

function Invoke-PSPipelineLinq
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[QueryType]
		[ValidateNotNull()]
		$QueryType,

		[Parameter(ValueFromRemainingArguments, Position=2)]  # FIXME: does a position work for a remaining arguments parameter?
		[Alias('Args')]
		$Arguments,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		switch (QueryType) {
			Aggregate { $Input | Invoke-PSPipelineLinqAggregate @Arguments }
			All { $Input | Invoke-PSPipelineLinqAll @Arguments }
			Any { $Input | Invoke-PSPipelineLinqAny @Arguments }
			Append { $Input | Invoke-PSPipelineLinqAppend @Arguments }
			AppendMany { $Input | Invoke-PSPipelineLinqAppendMany @Arguments }
			AsEnumerable { $Input | Invoke-PSPipelineLinqAsEnumerable @Arguments }
			Average { $Input | Invoke-PSPipelineLinqAverage @Arguments }
			Concat { $Input | Invoke-PSPipelineLinqConcat @Arguments }
			ConcatMany { $Input | Invoke-PSPipelineLinqConcatMany @Arguments }
			Contains { $Input | Invoke-PSPipelineLinqContains @Arguments }
			ContainsAll { $Input | Invoke-PSPipelineLinqContainsAll @Arguments }
			ContainsAny { $Input | Invoke-PSPipelineLinqContainsAny @Arguments }
			Count { $Input | Invoke-PSPipelineLinqCount @Arguments }
			DefaultIfEmpty { $Input | Invoke-PSPipelineLinqDefaultIfEmpty @Arguments }
			Distinct { $Input | Invoke-PSPipelineLinqDistinct @Arguments }
			ElementAt { $Input | Invoke-PSPipelineLinqElementAt @Arguments }
			ElementAtOrDefault { $Input | Invoke-PSPipelineLinqElementAtOrDefault @Arguments }
			Except { $Input | Invoke-PSPipelineLinqExcept @Arguments }
			First { $Input | Invoke-PSPipelineLinqFirst @Arguments }
			FirstOrDefault { $Input | Invoke-PSPipelineLinqFirstOrDefault @Arguments }
			GroupBy { $Input | Invoke-PSPipelineLinqGroupBy @Arguments }
			GroupJoin { $Input | Invoke-PSPipelineLinqGroupJoin @Arguments }
			Intersect { $Input | Invoke-PSPipelineLinqIntersect @Arguments }
			Join { $Input | Invoke-PSPipelineLinqJoin @Arguments }
			Last { $Input | Invoke-PSPipelineLinqLast @Arguments }
			LastOrDefault { $Input | Invoke-PSPipelineLinqLastOrDefault @Arguments }
			Max { $Input | Invoke-PSPipelineLinqMax @Arguments }
			Min { $Input | Invoke-PSPipelineLinqMin @Arguments }
			OfType { $Input | Invoke-PSPipelineLinqOfType @Arguments }
			OrderBy { $Input | Invoke-PSPipelineLinqOrderBy @Arguments }
			OrderByDescending { $Input | Invoke-PSPipelineLinqOrderByDescending @Arguments }
			Prepend { $Input | Invoke-PSPipelineLinqPrepend @Arguments }
			PrependMany { $Input | Invoke-PSPipelineLinqPrependMany @Arguments }
			Range { $Input | Invoke-PSPipelineLinqRange @Arguments }
			Repeat { $Input | Invoke-PSPipelineLinqRepeat @Arguments }
			Reverse { $Input | Invoke-PSPipelineLinqReverse @Arguments }
			Select { $Input | Invoke-PSPipelineLinqSelect @Arguments }
			SelectMany { $Input | Invoke-PSPipelineLinqSelectMany @Arguments }
			SequenceEqual { $Input | Invoke-PSPipelineLinqSequenceEqual @Arguments }
			Single { $Input | Invoke-PSPipelineLinqSingle @Arguments }
			SingleOrDefault { $Input | Invoke-PSPipelineLinqSingleOrDefault @Arguments }
			Skip { $Input | Invoke-PSPipelineLinqSkip @Arguments }
			SkipLast { $Input | Invoke-PSPipelineLinqSkipLast @Arguments }
			SkipWhile { $Input | Invoke-PSPipelineLinqSkipWhile @Arguments }
			Sum { $Input | Invoke-PSPipelineLinqSum @Arguments }
			Take { $Input | Invoke-PSPipelineLinqTake @Arguments }
			TakeLast { $Input | Invoke-PSPipelineLinqTakeLast @Arguments }
			TakeWhile { $Input | Invoke-PSPipelineLinqTakeWhile @Arguments }
			ToArray { $Input | Invoke-PSPipelineLinqToArray @Arguments }
			ToDictionary { $Input | Invoke-PSPipelineLinqToDictionary @Arguments }
			ToHashSet { $Input | Invoke-PSPipelineLinqToHashSet @Arguments }
			ToList { $Input | Invoke-PSPipelineLinqToList @Arguments }
			ToLookup { $Input | Invoke-PSPipelineLinqToLookup @Arguments }
			Union { $Input | Invoke-PSPipelineLinqUnion @Arguments }
			Where_ { $Input | Invoke-PSPipelineLinqWhere @Arguments }
			Zip { $Input | Invoke-PSPipelineLinqZip @Arguments }
			default { throw "Unrecognized query type: ""$QueryType""" }
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinq')


function Invoke-PSPipelineLinqAggregate
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
        [Parameter()]
        [Alias('Seed')]
        $InitialValue,

        [Parameter(Position=0)]
        [ScriptBlock]
        [ValidateNotNull()]
        [Alias('Func')]
        $AccumulatorFunction = { $args[0] + $args[1] },

        [Parameter()]
        [ScriptBlock]
        [ValidateNotNull()]
        [Alias('ResultSelector')]
        $ResultSelectorFunction = { $args[0] },

        [Parameter(Mandatory, ValueFromPipeline)]
        $InputObject
    )
    end {
        if (-not $MyInvocation.BoundParameters.ContainsKey('InitialValue')) {
			$Input.MoveNext() | Out-Null
			$InitialValue = $Input.Current  # $null if $Input did not have next
		}

        $Result = $InitialValue
        while ($Input.MoveNext()) {
            $Result = & $AccumulatorFunction $Result $Input.Current
        }
        $Result = & $ResultSelectorFunction $Result

        return $Result
    }
}
$ExportFunctions.Add('Invoke-PSPipelineLinqAggregate')
$ExportAliases.Add('Query-Aggregate')


function Invoke-PSPipelineLinqAll
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
        [Parameter(Position=0)]
        [ScriptBlock]
		[ValidateNotNull()]
		[Alias('Predicate')]
        $PredicateFunction = { [bool] $args[0] },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		while ($Input.MoveNext()) {
			if (-not (& $PredicateFunction $Input.Current)) {
				return $false
			}
		}
		return $true
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqAll')
$ExportAliases.Add('Query-All')


function Invoke-PSPipelineLinqAny
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=0)]
        [ScriptBlock]
		[ValidateNotNull()]
		[Alias('Predicate')]
		$PredicateFunction = { [bool] $args[0] },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		while ($Input.MoveNext()) {
			if (& $PredicateFunction $Input.Current) {
				return $true
			}
		}
		return $false
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqAny')
$ExportAliases.Add('Query-Any')


function Invoke-PSPipelineLinqAppend
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		$Element = $null,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	process {
		return $_
	}
	end {
		return $Element
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqAppend')
$ExportAliases.Add('Query-Append')


function Invoke-PSPipelineLinqAppendMany
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		$Elements = @(),

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	process {
		return $_
	}
	end {
		foreach ($Element in $Elements) {
			Write-Output $Element
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqAppendMany')
$ExportAliases.Add('Query-AppendMany')


function Invoke-PSPipelineLinqAsEnumerable
{
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		return New-Object Trintech.PowerShell.Linq.EnumeratorEnumerable $Input
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqAsEnumerable')
$ExportAliases.Add('Query-AsEnumerable')


function Invoke-PSPipelineLinqAverage
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=0)]
        [ScriptBlock]
        [ValidateNotNull()]
        [Alias('Selector')]
		$SelectorFunction = { $args[0] },

		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject
	)
	end {
		$Count = 0
		$Result = 0

		while ($Input.MoveNext()) {
			$Count += 1
			$Result += $Input.Current
		}
		$Result = $Result / $Count

		return $Result
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqAverage')
$ExportAliases.Add('Query-Average')


function Invoke-PSPipelineLinqConcat
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=0)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		[Alias('Second')]
		$Sequence = @(),

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	process {
		return $_
	}
	end {
		foreach ($Element in $Sequence) {
			Write-Output $Element
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqConcat')
$ExportAliases.Add('Query-Concat')


function Invoke-PSPipelineLinqConcatMany
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=0)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		$Sequences = @(),

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	process {
		return $_
	}
	end {
		foreach ($Sequence in $Sequences) {
			foreach ($Element in $Sequence) {
				Write-Output $Element
			}
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqConcatMany')
$ExportAliases.Add('Query-ConcatMany')


function Invoke-PSPipelineLinqContains
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		$Value,

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$EqualityPredicate = { $args[0] -eq $arg[1] },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		foreach ($Element in $Input) {
			if (& $ComparerFunction $Value $Element) {
				return $true
			}
		}
		return $false
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqContains')
$ExportAliases.Add('Query-Contains')


function Invoke-PSPipelineLinqContainsAll
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		$ValuesSequence,

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$EqualityPredicate = { $args[0] -eq $arg[1] },

		[Parameter(Position=3)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$HashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		#region Initialize
		$EqualityComparer = New-Object Trintech.PowerShell.Linq.PSEqualityComparer $EqualityPredicate $HashFunction
		$ValuesNotContained = New-Object System.Collections.HashFunction $EqualityComparer
		foreach ($Value in $ValuesSequence) {
			if (-not $ValuesNotContained.ContainsKey($Value)) {
				$ValuesNotContained.Add($Value, $Value)
			}
		}
		#endregion

		foreach ($Element in $Input) {
			if ($ValuesNotContained.ContainsKey($Element)) {
				$ValuesNotContained.Remove($Element)
			}
			if ($ValuesNotContained.Count -eq 0) {  # short-circuit
				return $true
			}
		}
		return $ValuesNotContained.Count -eq 0  # need to restate this here in case of no input elements and no values
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqContainsAll')
$ExportAliases.Add('Query-ContainsAll')


function Invoke-PSPipelineLinqContainsAny
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		$ValuesSequence,

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$EqualityPredicate = { $args[0] -eq $arg[1] },

		[Parameter(Position=3)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$HashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		#region Initialize
		$EqualityComparer = New-Object Trintech.PowerShell.Linq.PSEqualityComparer $EqualityPredicate $HashFunction
		$ValuesDictionary = New-Object System.Collections.Hashtable $EqualityComparer
		foreach ($Value in $ValuesSequence) {
			if (-not $ValuesDictionary.ContainsKey($Value)) {
				$ValuesDictionary.Add($Value, $Value)
			}
		}
		#endregion

		foreach ($Element in $Input) {
			if ($ValuesDictionary.ContainsKey($Element)) {
				return $true
			}
		}
		return $false
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqContainsAny')
$ExportAliases.Add('Query-ContainsAny')


function Invoke-PSPipelineLinqCount
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Predicate')]
		$PredicateFunction = { $true },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$Count = 0
		foreach ($Element in $Input) {
			if (& $PredicateFunction $Element) {
				$Count += 1
			}
		}
		return $Count
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqCount')
$ExportAliases.Add('Query-Count')


function Invoke-PSPipelineLinqDefaultIfEmpty
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=0)]
		$DefaultValue = $null,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$Result = $DefaultValue
		if ($Input.MoveNext()) {
			$Input.Reset()
			$Result = $Input
		}
		return $Result
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqDefaultIfEmpty')
$ExportAliases.Add('Query-DefaultIfEmpty')


function Invoke-PSPipelineLinqDistinct
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$EqualityPredicate = { $args[0] -eq $args[1] },

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$HashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$EqualityComparer = New-Object Trintech.PowerShell.Linq.PSEqualityComparer $EqualityPredicate $HashFunction
		$ElementsEncountered = New-Object System.Collections.Hashtable $EqualityComparer
	}
	process {
		if (-not $ElementsEncountered.ContainsKey($_)) {
			$ElementsEncountered.Add($_, $_)
			return $_
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqDistinct')
$ExportAliases.Add('Query-Distinct')


function Invoke-PSPipelineLinqElementAt
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[int]
		[ValidateNotNull()]
		[ValidateRange(0, [int]::MaxValue)]
		$Index,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$CurrentIndex = 0
	}
	process {
		if ($CurrentIndex -eq $Index) {
			$_
		}
		$CurrentIndex += 1
	}
	end {
		if ($Index -ge $CurrentIndex) {
			throw New-Object System.ArgumentOutOfRangeException
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqElementAt')
$ExportAliases.Add('Query-ElementAt')


function Invoke-PSPipelineLinqElementAtOrDefault
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[int]
		[ValidateRange(0, [int]::MaxValue)]
		$Index,

		[Parameter(Position=2)]
		$Default = $null,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$CurrentIndex = 0
	}
	process {
		if ($CurrentIndex -eq $Index) {
			$_
		}
		$CurrentIndex += 1
	}
	end {
		if ($Index -ge $CurrentIndex) {
			return $Default
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqElementAtOrDefault')
$ExportAliases.Add('Query-ElementAtOrDefault')


function Invoke-PSPipelineLinqExcept
{
	<#
	.SYNOPSIS
		Produces the set difference of the pipeline less the given values.
	.DESCRIPTION
		Evaluates the pipeline online.  Does not cache intermediate output.
		Assumes that neither the pipeline nor the given values constitute a set.
		The resulting pipeline may comprise a multi-set.
	#>
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		$ValuesSequence,

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$EqualityPredicate = { $args[0] -eq $arg[1] },

		[Parameter(Position=3)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$HashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$EqualityComparer = New-Object Trintech.PowerShell.Linq.PSEqualityComparer $EqualityPredicate $HashFunction
		$ValuesDictionary = New-Object System.Collections.Hashtable $EqualityComparer
		foreach ($Value in $ValuesSequence) {
			if (-not $ValuesDictionary.ContainsKey($Value)) {
				$ValuesDictionary.Add($Value, $Value)
			}
		}
	}
	process {
		if (-not $ValuesDictionary.ContainsKey($_)) {
			return $_
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqExcept')
$ExportAliases.Add('Query-Except')


function Invoke-PSPipelineLinqFirst
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Predicate')]
		$PredicateFunction = { $true },

		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject
	)
	begin {
		$Found = $false
	}
	process {
		if (-not $Found -and (& $PredicateFunction $_)) {
			$Found = $true
			return $_
		}
	}
	end {
		if (-not $Found) {
			throw New-Object System.InvalidOperationException
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqFirst')
$ExportAliases.Add('Query-First')


function Invoke-PSPipelineLinqFirstOrDefault
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Predicate')]
		$PredicateFunction = { $true },

		[Parameter(Position=2)]
		$Default = $null,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$Found = $false
	}
	process {
		if (-not $Found -and (& $PredicateFunction $_)) {
			$Found = $true
			return $_
		}
	}
	end {
		if (-not $Found) {
			return $Default
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqFirstOrDefault')
$ExportAliases.Add('Query-FirstOrDefault')


function Invoke-PSPipelineLinqGroupBy
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('KeySelector')]
		$KeySelectionFunction = { $args[0] },

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('ElementSelector')]
		$ElementSelectionFunction = { $args[0] },

		[Parameter(Position=3)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('ResultSelector')]
		$ResultSelectionFunction = { $args[0] },

		[Parameter(Position=4)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$KeyEqualityPredicate = { $args[0] -eq $args[1] },

		[Parameter(Position=5)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$KeyHashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$EqualityComparer = New-Object Trintech.PowerShell.Linq.EqualityComparer $KeyEqualityPredicate $KeyHashFunction
		$GroupsDictionary = New-Object System.Collections.Specialized.OrderedDictionary $EqualityComparer
		foreach ($SourceElement in $Input) {
			$Key = & $KeySelectionFunction $SourceElement
			if (-not $GroupsDictionary.Contains($Key)) {
				$MembersList = New-Object System.Collections.ArrayList
				$GroupsDictionary.Add($Key, $MembersList)
			}
			$Element = & $ElementSelectionFunction $SourceElement
			$GroupsDictionary[$Key].Add($Element)
		}
		foreach ($GroupMembers in $GroupsDictionary.Values) {  # in order of adding the groups
			$Result = & $ResultSelectionFunction $GroupMembers
			Write-Output $Result
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqGroupBy')
$ExportAliases.Add('Query-GroupBy')


function Invoke-PSPipelineLinqGroupJoin
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		[Alias('Inner', 'Second')]
		$RightSequence,

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('LeftKeySelector')]
		$LeftKeySelectionFunction = { $args[0] },

		[Parameter(Position=3)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('RightKeySelector')]
		$RightKeySelectionFunction = { $args[0] },

		[Parameter(Position=4)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('ResultSelector')]
		$ResultSelectionFunction = { $args[0] },

		[Parameter(Position=5)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$KeyEqualityPredicate = { $args[0] -eq $args[1] },

		[Parameter(Position=6)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$KeyHashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$EqualityComparer = New-Object Trintech.PowerShell.Linq.PSEqualityComparer $KeyEqualityPredicate $KeyHashFunction
		$RightDictionary = New-Object System.Collections.Hashtable $EqualityComparer
		foreach ($Element in $RightSequence) {
			$Key = & $RightKeySelectionFunction $Element
			if (-not $RightDictionary.ContainsKey($Key)) {
				$List = New-Object System.Collections.ArrayList
				$RightDictionary.Add($Key, $List)
			}
			$RightDictionary[$Key].Add($Element)
		}
	}
	process {
		$LeftElement = $_
		$Key = & $LeftKeySelectionFunction $LeftElement
		if ($RightDictionary.ContainsKey($Key)) {
			$RightGroup = $RightDictionary[$Key]
			$Result = & $ResultSelectionFunction $LeftElement $RightGroup
			Write-Output $Result
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqGroupJoin')
$ExportAliases.Add('Query-GroupJoin')


function Invoke-PSPipelineLinqIntersect
{
	<#
	.SYNOPSIS
		Produces the set intersection of the pipeline and the given values.
	.DESCRIPTION
		Evaluates the pipeline online.  Does not cache intermediate output.
		Assumes that neither the pipeline nor the given values constitute a set.
		The resulting pipeline may comprise a multi-set.
	#>
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		$ValuesSequence,

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$EqualityPredicate = { $args[0] -eq $arg[1] },

		[Parameter(Position=3)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$HashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$EqualityComparer = New-Object Trintech.PowerShell.Linq.PSEqualityComparer $EqualityPredicate $HashFunction
		$ValuesDictionary = New-Object System.Collections.Hashtable $EqualityComparer
		foreach ($Value in $ValuesSequence) {
			if (-not $ValuesDictionary.ContainsKey($Value)) {
				$ValuesDictionary.Add($Value, $Value)
			}
		}
	}
	process {
		if ($ValuesDictionary.ContainsKey($_)) {
			return $_
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqIntersect')
$ExportAliases.Add('Query-Intersect')


function Invoke-PSPipelineLinqJoin
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		[Alias('Inner', 'Second')]
		$RightSequence,

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('LeftKeySelector')]
		$LeftKeySelectionFunction = { $args[0] },

		[Parameter(Position=3)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('RightKeySelector')]
		$RightKeySelectionFunction = { $args[0] },

		[Parameter(Position=4)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('ResultSelector')]
		$ResultSelectionFunction = { $args[0] },

		[Parameter(Position=5)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$KeyEqualityPredicate = { $args[0] -eq $args[1] },

		[Parameter(Position=6)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$KeyHashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$EqualityComparer = New-Object Trintech.PowerShell.Linq.PSEqualityComparer $KeyEqualityPredicate $KeyHashFunction
		$RightDictionary = New-Object System.Collections.Hashtable $EqualityComparer
		foreach ($Element in $RightSequence) {
			$Key = & $RightKeySelectionFunction $Element
			if (-not $RightDictionary.ContainsKey($Key)) {
				$List = New-Object System.Collections.ArrayList
				$RightDictionary.Add($Key, $List)
			}
			$RightDictionary[$Key].Add($Element)
		}
	}
	process {
		$LeftElement = $_
		$Key = & $LeftKeySelectionFunction $LeftElement
		if ($RightDictionary.ContainsKey($Key)) {
			foreach ($RightElement in $RightDictionary[$Key]) {
				$ResultElement = & $ResultSelectionFunction $LeftElement $RightElement
				Write-Output $ResultElement
			}
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqJoin')
$ExportAliases.Add('Query-Join')


function Invoke-PSPipelineLinqLast
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Predicate')]
		$PredicateFunction = { $true },

		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject
	)
	end {
		$FoundAny = $false

		while ($Input.MoveNext()) {
			if (& $PredicateFunction $Input.Current) {
				$FoundAny = $true
				$Last = $Input.Current
			}
		}

		if (-not $FoundAny) {
			throw New-Object System.InvalidOperationException
		} else {
			return $Last
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqLast')
$ExportAliases.Add('Query-Last')


function Invoke-PSPipelineLinqLastOrDefault
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Predicate')]
		$PredicateFunction = { $true },

		[Parameter(Position=2)]
		$Default = $null,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$FoundAny = $false

		while ($Input.MoveNext()) {
			if (& $PredicateFunction $Input.Current) {
				$FoundAny = $true
				$Last = $Input.Current
			}
		}

		if (-not $FoundAny) {
			return $Default
		} else {
			return $Last
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqLastOrDefault')
$ExportAliases.Add('Query-LastOrDefault')


function Invoke-PSPipelineLinqMax
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Selector')]
		$ElementSelector = { $args[0] },

		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject
	)
	end {
		$Input.MoveNext() | Out-Null
		$Max = & $ElementSelector $Input.Current

		while ($Input.MoveNext()) {
			$Current = & $ElementSelector $Input.Current
			if ($Current -ge $Max) {
				$Max = $Current
			}
		}

		return $Max
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqMax')
$ExportAliases.Add('Query-Max')


function Invoke-PSPipelineLinqMin
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Selector')]
		$ElementSelector = { $args[0] },

		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject
	)
	end {
		$Input.MoveNext() | Out-Null
		$Min = & $ElementSelector $Input.Current

		while ($Input.MoveNext()) {
			$Current = & $ElementSelector $Input.Current
			if ($Current -lt $Min) {
				$Min = $Current
			}
		}

		return $Min
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqMin')
$ExportAliases.Add('Query-Min')


function Invoke-PSPipelineLinqOfType
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1, ParameterSetName='Type')]
		[string]
		[ValidateNotNullOrEmpty()]
		[Alias('Type')]
		$TypeName,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$Type = [PSObject].Assembly.GetInterface($TypeName, $true)  # returns null if not found
		if ($null -eq $Type) {
			$Type = [PSObject].Assembly.GetType($TypeName, $true, $true)  # throws exception if not found
		}
	}
	process {
		if ($Type.IsInstanceOfType($_)) {
			return $_
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqOfType')
$ExportAliases.Add('Query-OfType')


function Invoke-PSPipelineLinqOrderBy
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		$ComparisonFunction = {
			if ($args[0] -lt $args[1]) { -1 }
			elseif ($args[0] -gt $args[1]) { +1 }
			else { 0 }
		},

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$Comparer = New-Object Trintech.PowerShell.Linq.PSComparer $ComparisonFunction

		$Array = @($Input)
		[System.Array]::Sort($Array, $Comparer)

		return $Array
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqOrderBy')
$ExportAliases.Add('Query-OrderBy')


function Invoke-PSPipelineLinqOrderByDescending
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		$ComparisonFunction = {
			if ($args[0] -lt $args[1]) { -1 }
			elseif ($args[0] -gt $args[1]) { +1 }
			else { 0 }
		},

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$ReverseComparer = New-Object Trintech.PowerShell.Linq.PSReverseComparer $ComparisonFunction

		$Array = @($Input)
		[System.Array]::Sort($Array, $ReverseComparer)

		return $Array
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqOrderByDescending')
$ExportAliases.Add('Query-OrderByDescending')


function Invoke-PSPipelineLinqPrepend
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		$Element = $null,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		return $Element
	}
	process {
		return $_
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqPrepend')
$ExportAliases.Add('Query-Prepend')


function Invoke-PSPipelineLinqPrependMany
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		$Elements = @(),

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		foreach ($Element in $Elements) {
			Write-Output $Element
		}
	}
	process {
		return $_
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqPrependMany')
$ExportAliases.Add('Query-PrependMany')


function Invoke-PSPipelineLinqRange
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[Alias('Start')]
		$InitialValue = 0,

		[Parameter(Mandatory, Position=2)]
		[int]
		[ValidateNotNull()]
		[ValidateRange(0, [int]::MaxValue)]
		[Alias('Count')]
		$CountSteps,

		[Parameter(Position=3)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Successor')]
		$SuccessionFunction = { $args[0] + 1 }
	)
	begin {
		$Value = $InitialValue
		for ($Step = 0; $Step -lt $CountSteps; $Step += 1) {
			Write-Output $Value
			$Value = & $SuccessionFunction $Value
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqRange')
$ExportAliases.Add('Query-Range')


function Invoke-PSPipelineLinqRepeat
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		$Element = $null,

		[Parameter(Position=2)]
		[int]
		[ValidateNotNull()]
		[ValidateRange(0, [int]::MaxValue)]
		[Alias('Count')]
		$CountRepetitions = 0
	)
	begin {
		for ($Step = 0; $Step -lt $Count; $Step += 1) {
			Write-Output $Element
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqRepeat')
$ExportAliases.Add('Query-Repeat')


function Invoke-PSPipelineLinqReverse
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$Elements = @($Input)
		for ($Index = $Elements.Count - 1; $Index -ge 0; $Index -= 1) {
			Write-Output $Elements[$Index]
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqReverse')
$ExportAliases.Add('Query-Reverse')


function Invoke-PSPipelineLinqSelect
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Selector')]
		$SelectionFunction = { $args[0] },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	process {
		$Result = & $SelectionFunction $_
		return $Result
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqSelect')
$ExportAliases.Add('Query-Select')


function Invoke-PSPipelineLinqSelectMany
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('CollectionSelector')]
		$CollectionSelectionFunction = { @($args[0]) },

		[Parameter()]
		[switch]
		[Alias('IndexCollection')]
		$SelectCollectionWithIndex,

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('ResultSelector')]
		$ResultSelectionFunction = { $args[0] },

		[Parameter()]
		[switch]
		[Alias('IndexResult')]
		$SelectResultWithIndex,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$CollectionIndex = 0
		$ResultIndex = 0
	}
	process {
		$Collection = $(
			if ($SelectCollectionWithIndex) {
				& $CollectionSelectionFunction $_ $CollectionIndex
			} else {
				& $CollectionSelectionFunction $_
			}
		)
		$CollectionIndex += 1

		foreach ($Element in $Collection) {
			$Result = $(
				if ($SelectResultWithIndex) {
					& $ResultSelectionFunction $Element $ResultIndex
				} else {
					& $ResultSelectionFunction $Element
				}
			)
			$ResultIndex += 1

			Write-Output $Result
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqSelectMany')
$ExportAliases.Add('Query-SelectMany')


function Invoke-PSPipelineLinqSequenceEqual
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		$ValuesSequence,

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$EqualityPredicate = { $args[0] -eq $args[1] },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$Enumerator1 = $Input
		$Enumerator2 = $ValuesSequence.GetEnumerator()

		# initialize loop
		$HasNext1 = $Enumerator1.MoveNext()
		$HasNext2 = $Enumerator2.MoveNext()

		while ($HasNext1 -and $HasNext2) {
			$Current1 = $Enumerator1.Current
			$Current2 = $Enumerator2.Current

			if (-not (& $EqualityPredicate $Current1 $Current2)) {
				return $false
			}

			$HasNext1 = $Enumerator1.MoveNext()
			$HasNext2 = $Enumerator2.MoveNext()
		}

		return $HasNext1 -eq $HasNext2
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqSequenceEqual')
$ExportAliases.Add('Query-SequenceEqual')


function Invoke-PSPipelineLinqSingle
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Predicate')]
		$PredicateFunction = { $true },

		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject
	)
	end {
		$Found = $false
		foreach ($Element in $Input) {
			if (& $PredicateFunction $Element) {
				if ($Found) {
					throw New-Object InvalidOperationException 'More than one element satisfies the predicate condition.'
				}
				$Found = $true
				$Match = $Element
			}
		}
		if (-not $Found) {
			throw New-Object InvalidOperationException 'No element satisfies the predicate condition.'
		}
		return $Match
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqSingle')
$ExportAliases.Add('Query-Single')


function Invoke-PSPipelineLinqSingleOrDefault
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Predicate')]
		$PredicateFunction = { $true },

		[Parameter(Position=2)]
		[Alias('Default')]
		$DefaultValue = $null,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$Found = $false
		foreach ($Element in $Input) {
			if (& $PredicateFunction $Element) {
				if ($Found) {
					throw New-Object InvalidOperationException 'More than one element satisfies the predicate condition.'
				}
				$Found = $true
				$Match = $Element
			}
		}
		if (-not $Found) {
			return $DefaultValue
		}
		return $Match
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqSingleOrDefault')
$ExportAliases.Add('Query-SingleOrDefault')


function Invoke-PSPipelineLinqSkip
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[int]
		[Alias('Count')]
		$CountElements,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$Skipped = 0
	}
	process {
		if ($Skipped -lt $CountElements) {
			$Skipped += 1
		} else {
			return $Skipped
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqSkip')
$ExportAliases.Add('Query-Skip')


function Invoke-PSPipelineLinqSkipLast
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Parameter=1)]
		[int]
		[Alias('Count')]
		$CountElements,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$Elements = @($Input)
		for ($Index = 0; $Index -lt ($Elements.Count - $CountElements); $Index += 1) {
			Write-Output $Elements[$Index]
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqSkipLast')
$ExportAliases.Add('Query-SkipLast')


function Invoke-PSPipelineLinqSkipWhile
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		$Predicate = { $true },

		[Parameter()]
		[switch]
		[Alias('Index')]
		$WithIndex,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$Skip = $true
		$Index = 0
	}
	process {
		if (-not $Skip) {
			return $_
		}

		$While = $(
			if ($WithIndex) {
				& $Predicate $_ $Index
			} else {
				& $Predicate $_
			}
		)
		$Index += 1

		if (-not $While) {
			$Skip = $false
			return $_
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqSkipWhile')
$ExportAliases.Add('Query-SkipWhile')


function Invoke-PSPipelineLinqSum
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$Sum = 0
		foreach ($Num in $Input) {
			if ($null -ne $Num) {
				$Sum += $Num
			}
		}
		return $Sum
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqSum')
$ExportAliases.Add('Query-Sum')


function Invoke-PSPipelineLinqTake
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[int]
		$Count,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	process {
		if ($Count -gt 0) {
			$Count -= 1
			return $_
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqTake')
$ExportAliases.Add('Query-Take')


function Invoke-PSPipelineLinqTakeLast
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[int]
		$Count,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$Array = @($Input)
		for ($Index = ($Array.Count - $Count); $Index -lt $Array.Count; $Index += 1) {
			Write-Output $Array[$Index]
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqTakeLast')
$ExportAliases.Add('Query-TakeLast')


function Invoke-PSPipelineLinqTakeWhile
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		$Predicate = { $true },

		[Parameter()]
		[switch]
		[Alias('Index')]
		$WithIndex,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$Take = $true
		$Index = 0
	}
	process {
		if (-not $Take) {
			return
		}

		$While = $(
			if ($WithIndex) {
				& $Predicate $_ $Index
			} else {
				& $Predicate $_
			}
		)
		$Index += 1

		if ($While) {
			return $_
		} else {
			$Take = $false
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqTakeWhile')
$ExportAliases.Add('Query-TakeWhile')


function Invoke-PSPipelineLinqToArray
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$Array = @($Input)
		return $Array
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqToArray')
$ExportAliases.Add('Query-ToArray')


function Invoke-PSPipelineLinqToDictionary
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('KeySelector')]
		$KeySelectionFunction = { $args[0] },

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('ElementSelector')]
		$ElementSelectionFunction = { $args[0] },

		[Parameter(Position=3)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$KeyEqualityPredicate = { $args[0] -eq $args[1] },

		[Parameter(Position=4)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$KeyHashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$InputEnumerable = New-Object Trintech.PowerShell.Linq.EnumeratorEnumerable $Input
		$KeySelector = [Trintech.PowerShell.Linq.PSFunc]::CreateUnaryFunction($KeySelectionFunction)
		$ElementSelector = [Trintech.PowerShell.Linq.PSFunc]::CreateUnaryFunction($ElementSelectionFunction)
		$KeyEqualityComparer = New-Object Trintech.PowerShell.Linq.PSEqualityComparer $KeyEqualityPredicate $KeyHashFunction

		$Dictionary = [System.Linq.Enumerable]::ToDictionary($InputEnumerable, $KeySelector, $ElementSelector, $KeyEqualityComparer)

		return $Dictionary
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqToDictionary')
$ExportAliases.Add('Query-ToDictionary')


function Invoke-PSPipelineLinqToHashSet
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$EqualityPredicate = { $args[0] -eq $args[1] },

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$HashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$InputEnumerable = New-Object Trintech.PowerShell.Linq.PSEnumerable $Input
		$EqualityComparer = New-Object Trintech.PowerShell.Linq.PSEqualityComparer $EqualityPredicate $HashFunction

		$HashSet = [System.Linq.Enumerable]::ToHashSet($InputEnumerable, $EqualityComparer)

		return $HashSet
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqToHashSet')
$ExportAliases.Add('Query-ToHashSet')


function Invoke-PSPipelineLinqToList
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$InputEnumerable = New-Object Trintech.PowerShell.Linq.PSEnumerable $Input

		$List = [System.Linq.Enumerable]::ToList($InputEnumerable)

		return $List
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqToList')
$ExportAliases.Add('Query-ToList')


function Invoke-PSPipelineLinqToLookup
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('KeySelector')]
		$KeySelectionFunction = { $args[0] },

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('ElementSelector')]
		$ElementSelectionFunction = { $args[0] },

		[Parameter(Position=3)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$KeyEqualityPredicate = { $args[0] -eq $args[1] },

		[Parameter(Position=4)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$KeyHashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	end {
		$InputEnumerable = New-Object Trintech.PowerShell.Linq.EnumeratorEnumerable $Input
		$KeySelector = [Trintech.PowerShell.Linq.PSFunc]::CreateUnaryFunction($KeySelectionFunction)
		$ElementSelector = [Trintech.PowerShell.Linq.PSFunc]::CreateUnaryFunction($ElementSelectionFunction)
		$KeyEqualityComparer = New-Object Trintech.PowerShell.Linq.PSEqualityComparer $KeyEqualityPredicate $KeyHashFunction

		$Lookup = [System.Linq.Enumerable]::ToLookup($InputEnumerable, $KeySelector, $ElementSelector, $KeyEqualityComparer)

		return $Lookup
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqToLookup')
$ExportAliases.Add('Query-ToLookup')


function Invoke-PSPipelineLinqUnion
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		$ValuesSequence,

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Equals')]
		$EqualityPredicate = { $args[0] -eq $arg[1] },

		[Parameter(Position=3)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('GetHashCode')]
		$HashFunction = { $args[0].GetHashCode() },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$EqualityComparer = New-Object Trintech.PowerShell.Linq.PSEqualityComparer $EqualityPredicate $HashFunction
		$ValuesDictionary = New-Object System.Collections.Specialized.OrderedDictionary $EqualityComparer
		foreach ($Value in $ValuesSequence) {
			if (-not $ValuesDictionary.ContainsKey($Value)) {
				$ValuesDictionary.Add($Value, $Value)
			}
		}
		$ElementsDictionary = New-Object System.Collections.Hashtable $EqualityComparer
	}
	process {
		if (-not $ElementsDictionary.ContainsKey($_)) {
			$ElementsDictionary.Add($_, $_)
			if ($ValuesDictionary.ContainsKey($_)) {
				$ValuesDictionary.Remove($_)
			}
			return $_
		}
	}
	end {
		foreach ($Value in $ValuesDictionary.Values) {
			Write-Output $Value
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqUnion')
$ExportAliases.Add('Query-Union')


function Invoke-PSPipelineLinqWhere
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Position=1)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('Predicate')]
		$PredicateFunction = { $true },

		[Parameter()]
		[switch]
		[Alias('Index')]
		$WithIndex,

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$Index = 0
	}
	process {
		$IsWhere = $(
			if ($WithIndex) { & $PredicateFunction $_ $Index }
			else { & $PredicateFunction $_ }
		)
		if ($IsWhere) {
			Write-Output $_
		}
		$Index += 1
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqWhere')
$ExportAliases.Add('Query-Where')


function Invoke-PSPipelineLinqZip
{
	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory, Position=1)]
		[System.Collections.IEnumerable]
		[ValidateNotNull()]
		[Alias('Second')]
		$ValuesSequence,

		[Parameter(Position=2)]
		[ScriptBlock]
		[ValidateNotNull()]
		[Alias('ResultSelector')]
		$MergeFunction = { [System.Tuple]::Create($args[0], $args[1]) },

		[Parameter(ValueFromPipeline)]
		$InputObject
	)
	begin {
		$ValuesEnumerator = $ValuesSequence.GetEnumerator()
	}
	process {
		if ($ValuesEnumerator.MoveNext()) {
			return & $MergeFunction $_ $ValuesEnumerator.Current
		}
	}
}
$ExportFunctions.Add('Invoke-PSPipelineLinqZip')
$ExportAliases.Add('Query-Zip')


Export-ModuleMember `
	-Function $ExportFunctions `
	-Alias $ExportAliases
