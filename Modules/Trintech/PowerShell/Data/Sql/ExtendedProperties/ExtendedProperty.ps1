class ExtendedProperty
{
    static [string[]] $LEVEL_0_TYPES = @(
        'ASSEMBLY'
        'CONTRACT'
        'EVENT NOTIFICATION'
        'FILEGROUP'
        'MESSAGE TYPE'
        'PARTITION FUNCTION'
        'PARTITION SCHEME'
        'REMOTE SERVICE BINDING'
        'ROUTE'
        'SCHEMA'
        'SERVICE'
        'USER'
        'TRIGGER'
        'TYPE'
        'PLAN GUIDE'
    )

    static [string[]] $LEVEL_1_TYPES = @(
        'AGGREGATE'
        'DEFAULT'
        'FUNCTION'
        'LOGICAL FILE NAME'
        'PROCEDURE'
        'QUEUE'
        'RULE'
        'SYNONYM'
        'TABLE'
        'TABLE_TYPE'
        'TYPE'
        'VIEW'
        'XML SCHEMA COLLECTION'
    )

    static [string[]] $LEVEL_2_TYPES = @(
        'COLUMN'
        'CONSTRAINT'
        'EVENT NOTIFICATION'
        'INDEX'
        'PARAMETER'
        'TRIGGER'
    )

    [ValidateNotNull()][ValidateLength(128)][string] $name
    $value
    [ValidateLength(128)][string] $level0type
    [ValidateLength(128)][string] $level0name
    [ValidateLength(128)][string] $level1type
    [ValidateLength(128)][string] $level1name
    [ValidateLength(128)][string] $level2type
    [ValidateLength(128)][string] $level2name

    ExtendedProperty(
        [string] $name,
        $value,
        [string] $level0type,
        [string] $level0name,
        [string] $level1type,
        [string] $level1name,
        [string] $level2type,
        [string] $level2name
    ) {
        $this.ValidateHierarchy($level0name, $level1name, $level2name)

        $this.ValidateLevel($level0type, $level0name, 0)
        $this.ValidateLevel($level1type, $level1name, 1)
        $this.ValidateLevel($level2type, $level2name, 2)

        $this.ValidateType($level0type, 0)
        $this.ValidateType($level1type, 1)
        $this.ValidateType($level2type, 2)

        $this.ValidateName($level0name, 0)
        $this.ValidateName($level1name, 1)
        $this.ValidateName($level2name, 2)

        $this.ValidateName($name, -1)

        $this.name = $name
        $this.value = $value
        $this.level0type = $level0type
        $this.level0name = $level0name
        $this.level1type = $level1type
        $this.level1name = $level1name
        $this.level2type = $level2type
        $this.level2name = $level2name
    }

    hidden [void] ValidateHierarchy([string]$level0name, [string]$level1name, [string]$level2name)
    {
        if ($null -eq $level0name) {
            if ($null -ne $level1name -and -$null -ne $level2name) {
                throw "Error, if level0name is null, then so must be level1name=`"$level1name`" and level2name=`"$level2name`""
            }
            if ($null -ne $level1name) {
                throw "Error, if level0name is null, then so must be level1name=`"$level1name`""
            }
            if ($null -ne $level2name) {
                throw "Error, if level0name is null, then so must be level2name=`"$level1name`""
            }
        }
        if ($null -eq $level1name -and -not ($null -eq $level2name) ) {
            throw "Error, if level1name is null, then so must be level2name"
        }
    }

    hidden [void] ValidateLevel([string]$type, [string]$name, [int]$level)
    {
        if ( ($null -eq $type) -eq ($null -eq $name) ) {
            throw "Error, the type and name for level $($level) must either both be null or both not null"
        }
    }

    hidden [void] ValidateType([string]$type, [int]$level)
    {
        if ($null -ne $level) {
            $validTypes = switch ($level) {
                0 { $this.LEVEL_0_TYPES }
                1 { $this.LEVEL_1_TYPES }
                2 { $this.LEVEL_2_TYPES }
                default { throw "Error, unrecognized level=$level" }
            }
            if ($type -notin $validTypes) {
                $validTypesStr = @($validTypes) -join ', '
                throw "Error, level$($level))name must be in @($validTypesStr)"
            }
        }
    }

    hidden [void] ValidateName([string]$name, [int]$level)
    {
        $MAX_LENGTH = 128
        if ($null -eq $name) {
            if ($level -eq -1) {
                "Error, name may not be null"
            }
        }
        elseif ($name.Length -gt $MAX_LENGTH) {
            if ($level -eq -1) {
                $identifier = 'name'
            } else {
                $identifier = "level$($level))name"
            }
            throw "Error, $identifier may not be longer than $MAX_LENGTH characters"
        }
    }

    [boolean] Equals([ExtendedProperty]$other)
    {
        return (
            $null -ne $other -and
            $this.level0type -eq $other.level0type -and
            $this.level0name -eq $other.level0name -and
            $this.level1type -eq $other.level1type -and
            $this.level1name -eq $other.level1name -and
            $this.level2type -eq $other.level2type -and
            $this.level2name -eq $other.level2name -and
            $this.name -eq $other.name -and
            $this.value -eq $other.value
        )
    }

    [string] ToString()
    {
        return "ExtendedProperty{" + (@(
                "level0type=" + $this.QuoteIfNotNull($this.level0type)
                "level0name=" + $this.QuoteIfNotNull($this.level0name)
                "level1type=" + $this.QuoteIfNotNull($this.level1type)
                "level1name=" + $this.QuoteIfNotNull($this.level1name)
                "level2type=" + $this.QuoteIfNotNull($this.level2type)
                "level2name=" + $this.QuoteIfNotNull($this.level2name)
                "name=" + $this.QuoteIfNotNull($this.name)
                "value=" + $this.QuoteIfNotNull($this.value)
            ) -join '; ') + "}"
    }

    hidden [string] QuoteIfNotNull([string]$string, [string]$quote="'")
    {
        if ($null -ne $string) {
            $string = "'$string'"
        }
        return $string
    }
}