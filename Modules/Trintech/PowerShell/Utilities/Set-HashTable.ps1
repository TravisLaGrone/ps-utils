function Set-HashTable
{
    [CmdletBinding(PositionalBinding=$false)]
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [HashTable]
        [ValidateNotNull()]
        $HashTable,

        [Parameter(ParameterSetName='Item', ValueFromPipeline=$true, Mandatory=$true)]
        $Item,

        [Parameter(ParameterSetName='Item', Mandatory=$true, Position=2)]
        [ScriptBlock]
        [ValidateNotNull()]
        [Alias('GetKey')]
        $KeyScript,

        [Parameter(ParameterSetName='Item', Mandatory=$true, Position=3)]
        [ScriptBlock]
        [ValidateNotNull()]
        [Alias('GetValue')]
        $ValueScript,

        [Parameter(ParameterSetName='OtherHashTable', ValueFromPipeline=$true, Mandatory=$true, Position=2)]
        [HashTable]
        [ValidateNotNull()]
        $OtherHashTable
    )

    switch ($PSCmdlet.ParameterSetName) {
        Item {
            foreach ($Item in $Input) {
                $Key = $Item | ForEach-Object $KeyScript
                $Value = $Item | ForEach-Object $ValueScript
                $HashTable.Remove($Key)  # noop if doesn't contain key
                $HashTable.Add($Key, $Value)
            }
        }
        OtherHashTable {
            foreach ($OtherHashTable in $Input) {
                $OtherHashTable.GetEnumerator() |
                    Set-HashTable $HashTable { $_.Key } { $_.Value }
            }
        }
        default {
            throw "Error, unrecognized parameter set name: `"$($PSCmdlet.ParameterSetName)`""
        }
    }
    return $HashTable