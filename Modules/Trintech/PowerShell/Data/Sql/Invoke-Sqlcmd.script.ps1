[CmdletBinding(PositionalBinding=$false)]
param (
    [Parameter(Mandatory)]
    [string]
    [ValidateNotNull()]
    $SqlcmdArgumentCollectionsFileName,

    [Parameter(ValueFromRemainingArguments)]
    $SqlcmdRemainingArguments,

    [Parameter(Mandatory)]
    [string]
    $OutputFileName
)

