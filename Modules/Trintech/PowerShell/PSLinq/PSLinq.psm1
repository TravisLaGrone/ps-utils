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
	Empty
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

function Invoke-PSLinq
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
			Aggregate { $Input | Invoke-PSLinqAggregate @Arguments }
			All { $Input | Invoke-PSLinqAll @Arguments }
			Any { $Input | Invoke-PSLinqAny @Arguments }
			Append { $Input | Invoke-PSLinqAppend @Arguments }
			AppendMany { $Input | Invoke-PSLinqAppendMany @Arguments }
			AsEnumerable { $Input | Invoke-PSLinqAsEnumerable @Arguments }
			Average { $Input | Invoke-PSLinqAverage @Arguments }
			Concat { $Input | Invoke-PSLinqConcat @Arguments }
			ConcatMany { $Input | Invoke-PSLinqConcatMany @Arguments }
			Contains { $Input | Invoke-PSLinqContains @Arguments }
			ContainsAll { $Input | Invoke-PSLinqContainsAll @Arguments }
			ContainsAny { $Input | Invoke-PSLinqContainsAny @Arguments }
			Count { $Input | Invoke-PSLinqCount @Arguments }
			DefaultIfEmpty { $Input | Invoke-PSLinqDefaultIfEmpty @Arguments }
			Distinct { $Input | Invoke-PSLinqDistinct @Arguments }
			ElementAt { $Input | Invoke-PSLinqElementAt @Arguments }
			ElementAtOrDefault { $Input | Invoke-PSLinqElementAtOrDefault @Arguments }
			Empty { $Input | Invoke-PSLinqEmpty @Arguments }
			Except { $Input | Invoke-PSLinqExcept @Arguments }
			First { $Input | Invoke-PSLinqFirst @Arguments }
			FirstOrDefault { $Input | Invoke-PSLinqFirstOrDefault @Arguments }
			GroupBy { $Input | Invoke-PSLinqGroupBy @Arguments }
			GroupJoin { $Input | Invoke-PSLinqGroupJoin @Arguments }
			Intersect { $Input | Invoke-PSLinqIntersect @Arguments }
			Join { $Input | Invoke-PSLinqJoin @Arguments }
			Last { $Input | Invoke-PSLinqLast @Arguments }
			LastOrDefault { $Input | Invoke-PSLinqLastOrDefault @Arguments }
			Max { $Input | Invoke-PSLinqMax @Arguments }
			Min { $Input | Invoke-PSLinqMin @Arguments }
			OfType { $Input | Invoke-PSLinqOfType @Arguments }
			OrderBy { $Input | Invoke-PSLinqOrderBy @Arguments }
			OrderByDescending { $Input | Invoke-PSLinqOrderByDescending @Arguments }
			Prepend { $Input | Invoke-PSLinqPrepend @Arguments }
			Range { $Input | Invoke-PSLinqRange @Arguments }
			Repeat { $Input | Invoke-PSLinqRepeat @Arguments }
			Reverse { $Input | Invoke-PSLinqReverse @Arguments }
			Select { $Input | Invoke-PSLinqSelect @Arguments }
			SelectMany { $Input | Invoke-PSLinqSelectMany @Arguments }
			SequenceEqual { $Input | Invoke-PSLinqSequenceEqual @Arguments }
			Single { $Input | Invoke-PSLinqSingle @Arguments }
			SingleOrDefault { $Input | Invoke-PSLinqSingleOrDefault @Arguments }
			Skip { $Input | Invoke-PSLinqSkip @Arguments }
			SkipLast { $Input | Invoke-PSLinqSkipLast @Arguments }
			SkipWhile { $Input | Invoke-PSLinqSkipWhile @Arguments }
			Sum { $Input | Invoke-PSLinqSum @Arguments }
			Take { $Input | Invoke-PSLinqTake @Arguments }
			TakeLast { $Input | Invoke-PSLinqTakeLast @Arguments }
			TakeWhile { $Input | Invoke-PSLinqTakeWhile @Arguments }
			ToArray { $Input | Invoke-PSLinqToArray @Arguments }
			ToDictionary { $Input | Invoke-PSLinqToDictionary @Arguments }
			ToHashSet { $Input | Invoke-PSLinqToHashSet @Arguments }
			ToList { $Input | Invoke-PSLinqToList @Arguments }
			ToLookup { $Input | Invoke-PSLinqToLookup @Arguments }
			Union { $Input | Invoke-PSLinqUnion @Arguments }
			Where_ { $Input | Invoke-PSLinqWhere_ @Arguments }
			Zip { $Input | Invoke-PSLinqZip @Arguments }
			default { throw "Unrecognized query type: ""$QueryType""" }
		}
	}
}
$ExportFunctions.Add('Invoke-PSLinq')


function Invoke-PSLinqAggregate
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
$ExportFunctions.Add('Invoke-PSLinqAggregate')
$ExportAliases.Add('Query-Aggregate')


function Invoke-PSLinqAll
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
$ExportFunctions.Add('Invoke-PSLinqAll')
$ExportAliases.Add('Query-All')


function Invoke-PSLinqAny
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
$ExportFunctions.Add('Invoke-PSLinqAny')
$ExportAliases.Add('Query-Any')


function Invoke-PSLinqAppend
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
$ExportFunctions.Add('Invoke-PSLinqAppend')
$ExportAliases.Add('Query-Append')


function Invoke-PSLinqAppendMany
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
$ExportFunctions.Add('Invoke-PSLinqAppendMany')
$ExportAliases.Add('Query-AppendMany')


function Invoke-PSLinqAsEnumerable
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
$ExportFunctions.Add('Invoke-PSLinqAsEnumerable')
$ExportAliases.Add('Query-AsEnumerable')


function Invoke-PSLinqAverage
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
$ExportFunctions.Add('Invoke-PSLinqAverage')
$ExportAliases.Add('Query-Average')


function Invoke-PSLinqConcat
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
$ExportFunctions.Add('Invoke-PSLinqConcat')
$ExportAliases.Add('Query-Concat')


function Invoke-PSLinqConcatMany
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
$ExportFunctions.Add('Invoke-PSLinqConcatMany')
$ExportAliases.Add('Query-ConcatMany')


function Invoke-PSLinqContains
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
$ExportFunctions.Add('Invoke-PSLinqContains')
$ExportAliases.Add('Query-Contains')


function Invoke-PSLinqContainsAll
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
$ExportFunctions.Add('Invoke-PSLinqContainsAll')
$ExportAliases.Add('Query-ContainsAll')


function Invoke-PSLinqContainsAny
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
$ExportFunctions.Add('Invoke-PSLinqContainsAny')
$ExportAliases.Add('Query-ContainsAny')


function Invoke-PSLinqCount
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
$ExportFunctions.Add('Invoke-PSLinqCount')
$ExportAliases.Add('Query-Count')


function Invoke-PSLinqDefaultIfEmpty
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
$ExportFunctions.Add('Invoke-PSLinqDefaultIfEmpty')
$ExportAliases.Add('Query-DefaultIfEmpty')


function Invoke-PSLinqDistinct
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
$ExportFunctions.Add('Invoke-PSLinqDistinct')
$ExportAliases.Add('Query-Distinct')


function Invoke-PSLinqElementAt
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
$ExportFunctions.Add('Invoke-PSLinqElementAt')
$ExportAliases.Add('Query-ElementAt')


function Invoke-PSLinqElementAtOrDefault
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
$ExportFunctions.Add('Invoke-PSLinqElementAtOrDefault')
$ExportAliases.Add('Query-ElementAtOrDefault')


function Invoke-PSLinqExcept
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
$ExportFunctions.Add('Invoke-PSLinqExcept')
$ExportAliases.Add('Query-Except')


function Invoke-PSLinqFirst
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
$ExportFunctions.Add('Invoke-PSLinqFirst')
$ExportAliases.Add('Query-First')


function Invoke-PSLinqFirstOrDefault
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
$ExportFunctions.Add('Invoke-PSLinqFirstOrDefault')
$ExportAliases.Add('Query-FirstOrDefault')


function Invoke-PSLinqGroupBy
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
$ExportFunctions.Add('Invoke-PSLinqGroupBy')
$ExportAliases.Add('Query-GroupBy')


function Invoke-PSLinqGroupJoin
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
$ExportFunctions.Add('Invoke-PSLinqGroupJoin')
$ExportAliases.Add('Query-GroupJoin')


function Invoke-PSLinqIntersect
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
$ExportFunctions.Add('Invoke-PSLinqIntersect')
$ExportAliases.Add('Query-Intersect')


function Invoke-PSLinqJoin
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
$ExportFunctions.Add('Invoke-PSLinqJoin')
$ExportAliases.Add('Query-Join')


function Invoke-PSLinqLast
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
$ExportFunctions.Add('Invoke-PSLinqLast')
$ExportAliases.Add('Query-Last')


function Invoke-PSLinqLastOrDefault
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
$ExportFunctions.Add('Invoke-PSLinqLastOrDefault')
$ExportAliases.Add('Query-LastOrDefault')


function Invoke-PSLinqMax
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
$ExportFunctions.Add('Invoke-PSLinqMax')
$ExportAliases.Add('Query-Max')


function Invoke-PSLinqMin
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
$ExportFunctions.Add('Invoke-PSLinqMin')
$ExportAliases.Add('Query-Min')


function Invoke-PSLinqOfType
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
$ExportFunctions.Add('Invoke-PSLinqOfType')
$ExportAliases.Add('Query-OfType')


function Invoke-PSLinqOrderBy
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
$ExportFunctions.Add('Invoke-PSLinqOrderBy')
$ExportAliases.Add('Query-OrderBy')


function Invoke-PSLinqOrderByDescending
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
$ExportFunctions.Add('Invoke-PSLinqOrderByDescending')
$ExportAliases.Add('Query-OrderByDescending')


function Invoke-PSLinqPrepend
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
$ExportFunctions.Add('Invoke-PSLinqPrepend')
$ExportAliases.Add('Query-Prepend')


function Invoke-PSLinqPrependMany
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
$ExportFunctions.Add('Invoke-PSLinqPrependMany')
$ExportAliases.Add('Query-PrependMany')


function Invoke-PSLinqRange
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
$ExportFunctions.Add('Invoke-PSLinqRange')
$ExportAliases.Add('Query-Range')


function Invoke-PSLinqRepeat
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
$ExportFunctions.Add('Invoke-PSLinqRepeat')
$ExportAliases.Add('Query-Repeat')


function Invoke-PSLinqReverse
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
$ExportFunctions.Add('Invoke-PSLinqReverse')
$ExportAliases.Add('Query-Reverse')


function Invoke-PSLinqSelect
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
$ExportFunctions.Add('Invoke-PSLinqSelect')
$ExportAliases.Add('Query-Select')


function Invoke-PSLinqSelectMany
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
$ExportFunctions.Add('Invoke-PSLinqSelectMany')
$ExportAliases.Add('Query-SelectMany')


function Invoke-PSLinqSequenceEqual
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
$ExportFunctions.Add('Invoke-PSLinqSequenceEqual')
$ExportAliases.Add('Query-SequenceEqual')


function Invoke-PSLinqSingle
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
$ExportFunctions.Add('Invoke-PSLinqSingle')
$ExportAliases.Add('Query-Single')


function Invoke-PSLinqSingleOrDefault
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
$ExportFunctions.Add('Invoke-PSLinqSingleOrDefault')
$ExportAliases.Add('Query-SingleOrDefault')


function Invoke-PSLinqSkip
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
$ExportFunctions.Add('Invoke-PSLinqSkip')
$ExportAliases.Add('Query-Skip')


function Invoke-PSLinqSkipLast
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
$ExportFunctions.Add('Invoke-PSLinqSkipLast')
$ExportAliases.Add('Query-SkipLast')


function Invoke-PSLinqSkipWhile
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
$ExportFunctions.Add('Invoke-PSLinqSkipWhile')
$ExportAliases.Add('Query-SkipWhile')


function Invoke-PSLinqSum
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
$ExportFunctions.Add('Invoke-PSLinqSum')
$ExportAliases.Add('Query-Sum')


function Invoke-PSLinqTake
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
$ExportFunctions.Add('Invoke-PSLinqTake')
$ExportAliases.Add('Query-Take')


function Invoke-PSLinqTakeLast
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
$ExportFunctions.Add('Invoke-PSLinqTakeLast')
$ExportAliases.Add('Query-TakeLast')


function Invoke-PSLinqTakeWhile
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
$ExportFunctions.Add('Invoke-PSLinqTakeWhile')
$ExportAliases.Add('Query-TakeWhile')


function Invoke-PSLinqToArray
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
$ExportFunctions.Add('Invoke-PSLinqToArray')
$ExportAliases.Add('Query-ToArray')


function Invoke-PSLinqToDictionary
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
$ExportFunctions.Add('Invoke-PSLinqToDictionary')
$ExportAliases.Add('Query-ToDictionary')


function Invoke-PSLinqToHashSet
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
$ExportFunctions.Add('Invoke-PSLinqToHashSet')
$ExportAliases.Add('Query-ToHashSet')


function Invoke-PSLinqToList
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
$ExportFunctions.Add('Invoke-PSLinqToList')
$ExportAliases.Add('Query-ToList')


function Invoke-PSLinqToLookup
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
$ExportFunctions.Add('Invoke-PSLinqToLookup')
$ExportAliases.Add('Query-ToLookup')


function Invoke-PSLinqUnion
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
$ExportFunctions.Add('Invoke-PSLinqUnion')
$ExportAliases.Add('Query-Union')


function Invoke-PSLinqWhere
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
$ExportFunctions.Add('Invoke-PSLinqWhere')
$ExportAliases.Add('Query-Where')


function Invoke-PSLinqZip
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
$ExportFunctions.Add('Invoke-PSLinqZip')
$ExportAliases.Add('Query-Zip')


Export-ModuleMember `
	-Function $ExportFunctions `
	-Alias $ExportAliases
