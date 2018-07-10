$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "ConvertTo-HashTable" {
    Context "custom objects" {
        $CustomObject = New-Object PSObject -Property @{ 'A'=1; 'B'=2; 'C'=3 } ;

        It "converts to hash table from scripts" {
            $Actual =
            # TODO
        }

        It "converts to hash table from properties" {
            # TODO
        }

        It "converts to hash table from methods" {
            # TODO
        }
    }
}