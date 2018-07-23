#Requires -Version 5.1
#Requires -Modules @{ ModuleName="ImportExcel"; ModuleVersion="5.0.1" }
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    [Alias('InPath')]
    $InputFilePath,

    [Parameter()]
    [String]
    $WorksheetName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]
    [Alias('OutPath')]
    $OutputFilePath = "$($PWD)ExtendedPropertyScript.sql",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [EnhancedExtendedPropertyRoutine]
    $Routine = 'AddOrUpdate',

    [Parameter()]
    [ValidateNotNull()]
    [HashTable]
    $Defaults = @{ level0type='SCHEMA'; level0name='dbo' },

    [Parameter()]
    [ValidateNotNull()]
    [HashTable]
    $Overrides = @{ },

    [Parameter()]
    [ValidateNotNull()]
    [Array]
    $IncludeColumns = @( ),

    [Parameter()]
    [ValidateNotNull()]
    [Array]
    $ExcludeColumns = @( 'basetype', '_notes' ),

    [Parameter()]
    [Switch]
    $Append,

    [Parameter()]
    [Switch]
    $NoClobber,

    [Parameter()]
    [Switch]
    $SkipNullValue
)


#region Imports
Import-Module ImportExcel
#endregion Imports


#region Constants
$ENDL = "`r`n"

$MAX_LENGTH = 128

$LEVELS = 0..2

$EXTENDED_PROPERTY_LEVEL_MEMBER_NAMES = @(
    'level0type'
    'level0name'
    'level1type'
    'level1name'
    'level2type'
    'level2name'
)

$EXTENDED_PROPERTY_MEMBER_NAMES = @('name', 'value') + $EXTENDED_PROPERTY_LEVEL_MEMBER_NAMES

$FORMAT_ARGUMENT_LIST = @{
    LeftQuote = ''''
    RightQuote = ''''
    EscapeSequence = ''''
    ValueIfNull = 'NULL'
    PassThruIfNotString = $true
}
#endregion Constants


#region Initialize Script
$ImportExcelArgumentList = @{
    Path = $InputFilePath
}
if ($null -eq $WorksheetName) {
    $ImportExcelArgumentList.Add('WorksheetName', $WorksheetName)
}

$Append = [bool] $Append
$NoClobber = [bool] $NoClobber
$SkipNullValue = [bool] $SkipNullValue
#endregion Initialize Script


#region Helper Functions
function New-Array { $Input }

filter ConvertTo-Pipeline {
    foreach ($Element in $_) {
        $Element
    }
}

function Select-Unique {
    return $Input | Select-Object -Unique
}

enum SetOperation { Union; Intersection; Difference; CrossProduct }

function Join-Set([SetOperation]$Operation) {
    <# Returns a copy. #>
    $HasInput = $Input.MoveNext()
    if (-not $HasInput) {
        return $null
    }
    if (-not $Operation) {
        return $Input | ConvertTo-Pipeline | Select-Object -Unique
    }
    switch ($Operation) {
        Difference {
            $Difference = $Input.Current.GetEnumerator() | Select-Unique
            while ($Input.MoveNext()) {
                $Other = $Input.Current | Select-Unique
                $Difference = $Difference | Where-Object { $_ -notin $Other }
            }
            return $Difference
        }
        default { throw "Error, unrecognized set operation `"$Operation`"" }
    }
}

filter ConvertTo-HashTable($MemberTypes) {
    $HashTable = @{ }
    foreach ($Property in $_.PSObject.Properties) {
        if (-not $MemberTypes -or $MemberTypes -contains $Property.MemberType) {
            $HashTable.Add($Property.Name, $Property.Value)
        }
    }
    return $HashTable
}

function Merge-HashTable {
    <# Returns a copy. #>
    $Merged = @{ }
    foreach ($HashTable in $Input) {
        foreach ($Entry in $HashTable.GetEnumerator()) {
            $Merged.Remove($Entry.Key)
            $Merged.Add($Entry.Key, $Entry.Value)
        }
    }
    return $Merged
}

filter Set-HashTable($Defaults, $Overrides) {
    <# Returns a copy. #>
    $Defaults, $_, $Overrides | Merge-HashTable
}

filter Select-HashTable($IncludeKeys, $ExcludeKeys) {
    $_ = $_.Clone()
    foreach ($Key in @($_.Keys)) {
        if (($IncludeKeys -and ($Key -notin $IncludeKeys)) -or
            ($ExcludeKeys -and ($Key -in $ExcludeKeys))
        ) {
            $_.Remove($Key)
        }
    }
    return $_
}

filter Edit-HashTable([Switch]$Melt, $Identifiers, $VariableName, $ValueName) {
    if ($Melt) {
        $Keys = @($_.Keys)
        if (($Keys, $Identifiers | Join-Set -Difference).Count -eq 0) {
            return $_
        }
        $IdHashTable = $_.Clone() | Select-HashTable -Include $Identifiers
        foreach ($Key in $Keys) {
            if ($Key -notin $Identifiers) {
                $VarValHashTable = @{ $VariableName=$Key; $ValueName=$_[$Key] }
                $Melted = $IdHashTable, $VarValHashTable | Merge-HashTable  # COMBAK input validation that $VariableName, $ValueName are not in $Identifiers
                $Melted
            }
        }
    }
    else {
        return $_
    }
}

filter Format-Quoted($LeftQuote='''', $RightQuote='''', $EscapeSequence='''', $ValueIfNull='', [Switch]$PassThruIfNotString) {
    if ($null -eq $_) {
        return $ValueIfNull
    }
    if ($_ -isnot [String] -and $PassThruIfNotString) {
        return $_
    }
    $String = [String] $_
    $Escaped = $String.Replace($RightQuote, $EscapeSequence + $RightQuote)
    $Quoted = $LeftQuote + $Escaped + $RightQuote
    return $Quoted
}

function Group-Partition([ScriptBlock]$EquivalenceFunction, [Switch]$Consecutive) {
    $Partitions = New-Object System.Collections.ArrayList
    if ($Consecutive) {
        #region Initialize Loop
        $Partition = New-Object System.Collections.ArrayList
        if ($Input.HasNext()) {
            $Partition.Add($Input.Current)
        }
        #endregion Initialize Loop

        #region Loop
        while ($Input.HasNext()) {
            $Previous = $Partition[$Partition.Count - 1]
            $Current = $Input.Current
            $Equivalent = Invoke-Command $EquivalenceFunction -InputObject @($Previous, $Current)
            if (-not $Equivalent) {
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
        # TODO
        throw (New-Object System.NotImplementedException)
    }
    return $Partitions
}

enum SqlTypeName {
    BigInt
    Binary
    Bit
    Char
    Cursor
    Date
    DateTime
    DateTime2
    DateTimeOffset
    Decimal
    Float
    Geography
    Geometry
    HierarchyId
    Image
    Int
    Money
    NChar
    NText
    Numeric
    NVarChar
    Real
    RowVersion
    SmallDateTime
    SmallInt
    SmallMoney
    Sql_Variant
    SysName
    Table
    Text
    Time
    TinyInt
    UniqueIdentifier
    VarBinary
    VarChar
    Xml
}

filter Test-SqlValue([SqlTypeName]$TypeName, [Integer]$MaxLength, [Switch]$NotNull, [Switch]$Nullable) {
    if ($NotNull -and $null -eq $_) {
        return $false
    }
    switch ($TypeName) {
        NVarChar {
            if ($MaxLength -and $null -ne $_ -and $_.Length -gt $MAX_LENGTH) { return $false }
        }
        VarChar {
            # TODO test if each character can fit in less than one byte
            if ($MaxLength -and $null -ne $_ -and $_.Length -gt $MAX_LENGTH) { return $false }
        }
        SysName {
            # TODO test if each character can fit in less than one byte
            if (-not $Nullable -and $null -eq $_) { return $false }
            if ($null -ne $_ -and $_.Length -gt 128) { return $false }
        }
        default {
            throw (New-Object System.NotImplementedException)
        }
    }
    return $true
}

enum ExtendedPropertyRoutine {
    Add
    Drop
    List
    Update
}

enum EnhancedExtendedPropertyRoutine {
    Add
    AddIfAbsent
    AddOrUpdate
    Drop
    DropIfPresent
    List
    # no ListIfPresent because that's the default behavior anyway
    ListOrAdd
    Update
    UpdateIfPresent
}

filter Test-ExtendedProperty([EnhancedExtendedPropertyRoutine]$Routine) {

    # Input Validation (+ handle enhanced routine types)
    if ($Routine -in [EnhancedExtendedPropertyRoutine].GetEnumNames() -and $Routine -notin [ExtendedPropertyRoutine].GetEnumNames()) {
        return switch($Routine) {
            AddIfAbsent {
                ($_ | Test-ExtendedProperty List) -and
                ($_ | Test-ExtendedProperty Add)
            }
            AddOrUpdate {
                ($_ | Test-ExtendedProperty List) -and
                ($_ | Test-ExtendedProperty Add) -and
                ($_ | Test-ExtendedProperty Update)
            }
            DropIfPresent {
                ($_ | Test-ExtendedProperty List) -and
                ($_ | Test-ExtendedProperty Drop)
            }
            ListOrAdd {
                ($_ | Test-ExtendedProperty List) -and
                ($_ | Test-ExtendedProperty Add)
            }
            UpdateIfPresent {
                ($_ | Test-ExtendedProperty List) -and
                ($_ | Test-ExtendedProperty Update)
            }
            default { throw "Error, unimplemented enhanced extended property routine: `"$Routine`"" }
        }
    }
    elseif ($Routine -notin @('Add', 'Drop', 'List', 'Update') -and $Routine -in [ExtendedPropertyRoutine].GetEnumNames()) {
        throw "Error, unimplemented extended property routine: `"$Routine`""
    }
    elseif ($Routine -notin [ExtendedPropertyRoutine].GetEnumNames()) {
        throw "Error, unrecognized extended property routine: `"$Routine`""
    }

    # Validate level types
    foreach ($Level in $LEVELS) {
        if (-not ($_["level$($Level)type"] | Test-SqlValue -TypeName 'VarChar' -MaxLength 128)) {
            return $false
        }
    }

    # Validate level names
    foreach ($Level in $LEVELS) {
        if (-not ($_["level$($Level)type"] | Test-SqlValue -TypeName 'SysName' -Nullable)) {
            return $false
        }
    }

    # Validate extended property name
    if ($Routine -eq 'List') {
        if (-not ($_['name'] | Test-SqlValue -TypeName 'SysName' -Nullable)) {
            return $false
        }
    }
    else {
        if (-not ($_['name'] | Test-SqlValue -TypeName 'SysName')) {
            return $false
        }
    }

    # Validate nullity for each level
    if ($Routine -eq 'List') {
        foreach ($Level in $LEVELS) {
            if (-not ($null -ne $_["level$($Level)type"] -or $null -eq $_["level$($Level)name"])) {
                return $false
            }
        }
    }
    else {
        foreach ($Level in $LEVELS) {
            if (-not (($null -eq $_["level$($Level)type"]) -eq ($null -eq $_["level$($Level)name"]))) {
                return $false
            }
        }
    }

    # Validate nullity for hierarchy of types
    $LeastNullTypeAlreadyEncountered = $false
    foreach ($Level in $LEVELS) {
        if ($LeastNullTypeAlreadyEncountered -and $null -ne $_["level$($Level)type"]) {
            return $false
        }
        if ($null -eq $_["level$($Level)type"]) {
            $LeastNullTypeAlreadyEncountered = $true
        }
    }

    # Validate nullity for set of names for 'List' routine (i.e. only one wilcard name permitted)
    if ($Routine -eq 'List') {
        $WildcardNameAlreadyEncountered = $false
        foreach ($Level in $LEVELS) {
            $IsWildcardName = $_[$null -ne "level$($Level)type" -and $null -eq "level$($Level)name"]
            if ($IsWildcardName -and $WildcardNameAlreadyEncountered) {
                return $false
            }
            if ($IsWildcardName) {
                $WildcardNameAlreadyEncountered = $true
            }
        }
        $IsWildcardName = $null -eq $_['name']
        if ($IsWildcardName -and $WildcardNameAlreadyEncountered) {
            return $false
        }
    }

    return $true
}

filter Format-ExtendedProperty([EnhancedExtendedPropertyRoutine]$Routine, [Switch]$Execute, [Switch]$SqlCmd, [Switch]$ValidateInput) {
    if ($ValidateInput -and -not ($_ | Test-ExtendedProperty $Routine)) {
        throw "Error, extended property is not valid for routine `"$Routine`": $_"
    }

    $name       = $_['name']       | Format-Quoted @FORMAT_ARGUMENT_LIST
    $value      = $_['value']      | Format-Quoted @FORMAT_ARGUMENT_LIST
    $level0type = $_['level0type'] | Format-Quoted @FORMAT_ARGUMENT_LIST
    $level0name = $_['level0name'] | Format-Quoted @FORMAT_ARGUMENT_LIST
    $level1type = $_['level1type'] | Format-Quoted @FORMAT_ARGUMENT_LIST
    $level1name = $_['level1name'] | Format-Quoted @FORMAT_ARGUMENT_LIST
    $level2type = $_['level2type'] | Format-Quoted @FORMAT_ARGUMENT_LIST
    $level2name = $_['level2name'] | Format-Quoted @FORMAT_ARGUMENT_LIST

    $Formatted = switch ($Routine) {
        AddIfAbsent {
            $List = $_ | Format-ExtendedProperty -Routine 'List' -Excute:$Execute -ValidateInput:$ValidateInput
            $Add  = $_ | Format-ExtendedProperty -Routine 'Add'  -Excute:$Execute -ValidateInput:$ValidateInput
            $Formatted = "IF (NOT EXISTS($List)) BEGIN $Add END"
            if ($SqlCmd) {
                $Formatted = "$Formatted;$($ENDL)GO"
            }
            $Formatted
        }
        AddOrUpdate {
            $List   = $_ | Format-ExtendedProperty -Routine 'List'   -Excute:$Execute -ValidateInput:$ValidateInput
            $Add    = $_ | Format-ExtendedProperty -Routine 'Add'    -Excute:$Execute -ValidateInput:$ValidateInput
            $Update = $_ | Format-ExtendedProperty -Routine 'Update' -Excute:$Execute -ValidateInput:$ValidateInput
            $Formatted = "IF (EXISTS($List)) BEGIN $Update END ELSE BEGIN $Add END"
            if ($SqlCmd) {
                $Formatted = "$Formatted;$($ENDL)GO"
            }
            $Formatted
        }
        DropIfPresent {
            $List = $_ | Format-ExtendedProperty -Routine 'List' -Excute:$Execute -ValidateInput:$ValidateInput
            $Drop = $_ | Format-ExtendedProperty -Routine 'Drop' -Excute:$Execute -ValidateInput:$ValidateInput
            $Formatted = "IF (EXISTS($List)) BEGIN $Drop END"
            if ($SqlCmd) {
                $Formatted = "$Formatted;$($ENDL)GO"
            }
            $Formatted
        }
        ListOrAdd {
            $List = $_ | Format-ExtendedProperty -Routine 'List' -Excute:$Execute -ValidateInput:$ValidateInput
            $Add  = $_ | Format-ExtendedProperty -Routine 'Add'    -Excute:$Execute -ValidateInput:$ValidateInput
            $Formatted = "IF (NOT EXISTS($List)) BEGIN $Add END"
            $Listed = $List
            if ($SqlCmd) {
                $Formatted = "$Formatted;"
                $Listed = "$Listed;$($ENDL)GO"
            }
            $Formatted = "$Formatted$($ENDL)$Listed"
            $Formatted
        }
        UpdateIfPresent {
            $List   = $_ | Format-ExtendedProperty -Routine 'List' -Excute:$Execute -ValidateInput:$ValidateInput
            $Update = $_ | Format-ExtendedProperty -Routine 'Update' -Excute:$Execute -ValidateInput:$ValidateInput
            $Formatted = "IF (EXISTS($List)) BEGIN $Update END"
            if ($SqlCmd) {
                $Formatted = "$Formatted;$($ENDL)GO"
            }
            $Formatted
        }
        default {
            $IdArgs = switch ($Routine) {
                Add    { $name, $value }
                Drop   { $name }
                List   { $name }
                Update { $name, $value }
                default { throw "Error, unrecognized extended property routine type: `"$Routine`"" }
            }
            $LevelArgs = $level0type, $level0name, $level1type, $level1name, $level2type, $level2name
            $ArgumentList = @($IdArgs) + @($LevelArgs)
            $ArgumentString = $ArgumentList -join ', '

            $Formatted = switch ($Routine) {
                Add    { "sys.sp_addextendedproperty $ArgumentString" }
                Drop   { "sys.sp_dropextendedproperty $ArgumentString" }
                List   { "sys.fn_listextendedproperty $ArgumentString" }
                Update { "sys.sp_updateextendedproperty $ArgumentString" }
                default { throw "Error, unrecognized extended property routine type: `"$Routine`"" }
            }

            if ($Execute) {
                $Formatted = "EXECUTE $Formatted"

                if ($SqlCmd) {
                    $Formatted = "$Formatted;$($ENDL)GO"
                }
            }

            $Formatted
        }
    }

    return $Formatted
}

function Join-String($Delimiter='') {
    <# Returns an empty string if no input. #>
    $Array = $Input | New-Array
    $Joined = @($Array) -join $Delimiter
    return $Joined
}
#endregion Helper Functions


Import-Excel @ImportExcelArgumentList |  # import raw rows as PSCustomObject; properties names are header row
    ConvertTo-HashTable -MemberTypes 'NoteProperty' |
    Set-HashTable -Defaults $Defaults -Overrides $Overrides |
    Select-HashTable -Include $IncludeColumns -Exclude $ExcludeColumns |
    ForEach-Object {  # melt (i.e. unpivot) name(s)
        if (@($_.Keys | Where-Object { $_ -notin $EXTENDED_PROPERTY_MEMBER_NAMES }).Count -gt 0) {
            $_ = $_ | Edit-HashTable -Melt -Id $EXTENDED_PROPERTY_LEVEL_MEMBER_NAMES -Var 'name' -Val 'value'
        }
        return $_
    } |
    Where-Object { -not $SkipNullValue -or $null -ne $_['value'] } |
    Format-ExtendedProperty -Execute -SqlCmd -Routine 'Add' |
    Join-String $ENDL |
    Out-File $OutputFilePath -Append:$Append -NoClobber:$NoClobber