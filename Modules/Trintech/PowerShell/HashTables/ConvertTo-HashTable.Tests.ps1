$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "ConvertTo-HashTable" {
    enum KeyParameter { IsKey; KeyMemberName; KeyScript }
    enum ValueParameter { IsValue; ValueMemberName; ValueScript }

    $Objects = 1..10 |
        ForEach-Object {
            New-Object `
                -TypeName 'PSCustomObject' `
                -Property @{
                    Number = $_
                    Letter = [char]($_ + 64)
                }
        } |
        Add-Member `
            -MemberType 'ScriptMethod' `
            -Name 'Get' `
            -Value {
                param([string]$PropertyName)
                return $this | Select-Object -ExpandProperty $PropertyName
            } `
            -PassThru ;

    It ""

}