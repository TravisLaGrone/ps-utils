# TODO test Select-Coalescence
# TODO document Select-Coalescence

#Requires -Version 5.1
function Select-Coalescence
{
    [CmdletBinding(PositionalBinding=$false)]
    Param (
        [Parameter(ValueFromRemainingArguments, Position=0)]
        [ScriptBlock[]]
        [ValidateScript({ $null -ne $_ -and $null -notin @($_) })]  # FIXME is this passed the entire array or each item in the array?
        $Defaults,

        [Parameter()]
        [ScriptBlock]
        [ValidateNotNull()]
        $Test = { $null -ne $_ },  # filter

        [Parameter(ValueFromPipeline)]
        [Object]
        $InputObject
    )
    End {
        foreach ($Element in $Input) {
            $IsValid = $Element | ForEach-Object $Test
            if ($IsValid) {
                return $Element
            }
        }
        foreach ($Default in $Defaults) {
            $Element = & $Default
            $IsValid = $Element | ForEach-Object $Test
            if ($IsValid) {
                return $Element
            }
        }
        return $null
    }
}

try {
    New-Alias -Name '??' -Value 'Select-Coalescence'
} catch {
    # no-op
}