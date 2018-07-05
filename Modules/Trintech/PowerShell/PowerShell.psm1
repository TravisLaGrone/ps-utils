# TODO document module

# Import Immediate Child Modules
$PSScriptRoot |
    Get-ChildItem -Directory |
    Get-ChildItem -File -Filter '*.psm1' |
    Select-Object -ExpandProperty Directory |
    Select-Object -ExpandProperty FullName |
    ForEach-Object {
        [regex]::Match($_,
            "^(?:" +
                "$($(Split-Path $PSScriptRoot -Parent).replace('\', '\\'))" +
            "\\)" +
            "(.*)"
        ).groups[1].value
    } |
    ForEach-Object {
        Import-Module $_
    } >$nul;