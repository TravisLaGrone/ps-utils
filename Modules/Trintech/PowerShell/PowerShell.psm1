# TODO document module

# Import Component Scripts
$PSScriptRoot |
    Get-ChildItem -File -Filter '*.ps1' |
    Select-Object -ExpandProperty 'FullName' |
    ForEach-Object {
        . "$_"
    } > $nul;

# Import Immediate Child Modules
$PSScriptRoot |
    Get-ChildItem -Directory |
    Get-ChildItem -File -Filter '*.psm1' |
    Select-Object -ExpandProperty 'Directory' |
    Select-Object -ExpandProperty 'FullName' |
    ForEach-Object {
        [regex]::Match($_,
            "^(?:" +
                "$($(Split-Path $PSScriptRoot -Parent).replace('\', '\\'))" +
            "\\)" +
            "(.*)"
        ).groups[1].value
    } |
    ForEach-Object {
        Import-Module "$_"
    } > $nul;