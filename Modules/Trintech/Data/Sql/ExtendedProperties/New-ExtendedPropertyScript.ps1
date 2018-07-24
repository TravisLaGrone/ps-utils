<#
.SYNOPSIS
    Creates a T-SQL extended property script.
.DESCRIPTION
    Creates a T-SQL extended property script from an Excel file of possibly
    pivoted extended property definitions, and writes the created script to a
    file. Unless the SqlCmd switch is set, the output will consist of exactly
    one complete extended property routine invocation per line.
.PARAMETER InputExcelPath
    The path of the input Excel file.
.PARAMETER WorksheetName
    The name of the worksheet to extract from the Excel file. If not specified,
    then the first worksheet is extracted.
.PARAMETER EndRow
    The row in the input Excel file worksheet at which the import is stopped. If
    not specified, then all rows are imported. May not be negative.
.PARAMETER OutputScriptPath
    The full name of the file to which to output the extended property script.
    If not specified, then the output is written to a file in the present
    working directory named "ExtendedPropertyScript.sql".
.PARAMETER Routine
    The T-SQL extended property routine or composition of routines to generate
    for each inputted extended property.
.PARAMETER Defaults
    The default fields and their values to create and assign to them for fields
    that do not have a corresponding column in the inputted Excel file. Fields
    that do have a corresponding column in the inputted Excel file are ignored,
    regardless of whether their inputted values are null. Note that the fields
    are relative to the input Excel file which is not necessarily normalized,
    rather than a normalized extended property definition. Any defaults must be
    passed as a single hash table, where the key is the field name and the value
    is the field value.
.PARAMETER Overrides
    The overriding fields and their values to assign to them for each row from
    the inputted Excel file. If the field already exists, its values is
    overriden. If the field does not exist, it is created with the given value.
    Note that the fifelds are relative to the input Excel file which is not
    necessarily normalized, rather than a normalized extended property definition.
    Any overrides must be passed as a single hash table, where the key is the
    field name and the value is the field value.
.PARAMETER IncludeColumns
    The set of columns from the input Excel file to include. Any columns whose
    names are not specified in this array are excluded. If no columns are specified,
    then all columns are included (subject to the argument for ExcludeColumns).
    This filter is applied subsequent to the application of the Defaults and
    Overrides, but prior to the ExcludeColumns filter. IncludeColumns that do not
    exist do not cause an error to be thrown.
.PARAMETER ExcludeColumns
    The set of columns from the input Excel file to exclude. Any columns whose
    names are specified in this array are excluded. If no columns are specified,
    then no columns are excluded (subject to the argument for IncludeColumns).
    This filter is applied subsequent to the application of the Defaults,
    Overrides, and IncludeColumns. ExcludeColumns that do not exist do not cause
    an error to be thrown.
.PARAMETER ValidateInput
    Indicates that each extended property will validated. This test is applied
    subsequence to the Defaults, Overrides, IncludeColumns, ExcludeColumns, and
    normalization.
.PARAMETER Execute
    Indicates that each scripted extended property routine invocation definition
    will be prefaced with the T-SQL `EXECUTE` command.
.PARAMETER SqlCmd
    Indicates that each scripted extended property routine EXECUTE statement
    will be formatted for SqlCmd (i.e. a semicolon, LF, CR, and "GO" will be
    appended). Only functions if the Execute switch is also set.
.PARAMETER Append
    Indicates that if the output script file already exists, then it is appended
    to rather than overwritten.
.PARAMETER NoClobber
    Indicates that an existing file will not be overwritten. However, it may be
    appended to if the Append switch it set.
.PARAMETER SkipNullValuess
    Indicates that extended properties whose "value" field is `null` will be
    skipped. This filter is applied subsequent to the application of the Defaults,
    Overrides, IncludeColumns, and ExcludeColumns, as well as normalization.
#>
#Requires -Version 5.1
#Requires -Modules @{ ModuleName="ImportExcel"; ModuleVersion="5.0.1" }
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    [Alias('InPath')]
    $InputExcelPath,

    [Parameter()]
    [String]
    $WorksheetName,

    [Parameter()]
    [ValidateScript({$_ -ge 0})]
    [Integer]
    $EndRow,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]
    [Alias('OutPath')]
    $OutputScriptPath = $(Join-Path $PWD 'ExtendedPropertyScript.sql'),

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    # [EnhancedExtendedPropertyRoutine]  # FIXME type is not yet defined
    $Routine = 'AddOrUpdate',

    [Parameter()]
    [ValidateNotNull()]
    [HashTable]
    $Defaults = @{ },

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
    $ExcludeColumns = @( ),

    [Parameter()]
    [Switch]
    $ValidateInput,

    [Parameter()]
    [Switch]
    $Execute,

    [Parameter()]
    [Switch]
    $SqlCmd,

    [Parameter()]
    [Switch]
    $Append,

    [Parameter()]
    [Switch]
    $NoClobber,

    [Parameter()]
    [Switch]
    $SkipNullValues
)
begin {
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
        PassThruIfNotString = $false
    }
    #endregion Constants


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
        <# Returns a copy. If multiple hash tables contain a key, the last hash table's entry takes precedence. #>
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

        $ExtendedProperty = $_

        $Formatted = switch ($Routine) {
            AddIfAbsent {
                $List = $ExtendedProperty | Format-ExtendedProperty -Routine 'List' -Execute -ValidateInput:$ValidateInput
                $Add  = $ExtendedProperty | Format-ExtendedPropeerty -Routine 'Add' -Execute -ValidateInput:$ValidateInput
                $Formatted = "IF (NOT EXISTS($List)) BEGIN $Ad eEND"
                if ($SqlCmd) {
                    $Formatted = "$Formatted;$($ENDL)GO"
                }
                $Formatted
            }
            AddOrUpdate {
                $List   = $ExtendedProperty | Format-ExtendedProperty -Routine 'List'   -Execute -ValidateInput:$ValidateInput
                $Add    = $ExtendedProperty | Format-ExtendedProperty -Routine 'Add'    -Execute -ValidateInput:$ValidateInput
                $Update = $ExtendedProperty | Format-ExtendedProperty -Routine 'Update' -Execute -ValidateInput:$ValidateInput
                $Formatted = "IF (EXISTS($List)) BEGIN $Update END ELSE BEGIN $Add END"
                if ($SqlCmd) {
                    $Formatted = "$Formatted;$($ENDL)GO"
                }
                $Formatted
            }
            DropIfPresent {
                $List = $ExtendedProperty | Format-ExtendedProperty -Routine 'List' -Execute -ValidateInput:$ValidateInput
                $Drop = $ExtendedProperty | Format-ExtendedProperty -Routine 'Drop' -Execute -ValidateInput:$ValidateInput
                $Formatted = "IF (EXISTS($List)) BEGIN $Drop END"
                if ($SqlCmd) {
                    $Formatted = "$Formatted;$($ENDL)GO"
                }
                $Formatted
            }
            ListOrAdd {
                $List = $ExtendedProperty | Format-ExtendedProperty -Routine 'List' -Execute -ValidateInput:$ValidateInput
                $Add  = $ExtendedProperty | Format-ExtendedProperty -Routine 'Add'  -Execute -ValidateInput:$ValidateInput
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
                $List   = $ExtendedProperty | Format-ExtendedProperty -Routine 'List'   -Execute -ValidateInput:$ValidateInput
                $Update = $ExtendedProperty | Format-ExtendedProperty -Routine 'Update' -Execute -ValidateInput:$ValidateInput
                $Formatted = "IF (EXISTS($List)) BEGIN $Update END"
                if ($SqlCmd) {
                    $Formatted = "$Formatted;$($ENDL)GO"
                }
                $Formatted
            }
            default {
                $name       = $ExtendedProperty['name']       | Format-Quoted @FORMAT_ARGUMENT_LIST
                $value      = $ExtendedProperty['value']      | Format-Quoted @FORMAT_ARGUMENT_LIST
                $level0type = $ExtendedProperty['level0type'] | Format-Quoted @FORMAT_ARGUMENT_LIST
                $level0name = $ExtendedProperty['level0name'] | Format-Quoted @FORMAT_ARGUMENT_LIST
                $level1type = $ExtendedProperty['level1type'] | Format-Quoted @FORMAT_ARGUMENT_LIST
                $level1name = $ExtendedProperty['level1name'] | Format-Quoted @FORMAT_ARGUMENT_LIST
                $level2type = $ExtendedProperty['level2type'] | Format-Quoted @FORMAT_ARGUMENT_LIST
                $level2name = $ExtendedProperty['level2name'] | Format-Quoted @FORMAT_ARGUMENT_LIST

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
                    List   { "sys.fn_listextendedproperty($ArgumentString)" }
                    Update { "sys.sp_updateextendedproperty $ArgumentString" }
                    default { throw "Error, unrecognized extended property routine type: `"$Routine`"" }
                }

                if ($Execute) {
                    if ($Routine -eq 'List') {
                        $Formatted = "SELECT * FROM $Formatted"
                    } else {
                        $Formatted = "EXECUTE $Formatted"
                    }

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


    #region Initialize Script
    $ImportExcelArgumentList = @{
        Path = $InputExcelPath
    }
    if ($WorksheetName) {
        $ImportExcelArgumentList.Add('WorksheetName', $WorksheetName)
    }
    if ($EndRow) {
        $ImportExcelArgumentList.Add('EndRow', $EndRow)
    }

    $Execute = [bool] $Execute
    $SqlCmd = [bool] $SqlCmd
    $Append = [bool] $Append
    $NoClobber = [bool] $NoClobber
    $SkipNullValues = [bool] $SkipNullValues
    $ValidateInput = [bool] $ValiateInput
    #endregion Initialize Script
}
process {
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
        Where-Object { -not $SkipNullValues -or $null -ne $_['value'] } |
        Format-ExtendedProperty -Routine $Routine -Execute:$Execute -SqlCmd:$SqlCmd -ValidateInput:$ValidateInput |
        Join-String $ENDL |
        Out-File $OutputScriptPath -Append:$Append -NoClobber:$NoClobber
}