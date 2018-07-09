function ConvertTo-HashTable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [System.Collections.IEnumerable]
        $Enumerable,

        [Parameter(Mandatory=$true, ParameterSetName='KeyName, ValueName')]
        [Parameter(Mandatory=$true, ParameterSetName='KeyName, ValueScript')]
        [String]
        $KeyMemberName,

        [Parameter(ParameterSetName='KeyName, ValueName')]
        [Parameter(ParameterSetName='KeyName, ValueScript')]
        [Object[]]
        $KeyArgumentList,

        # The script to extract the key from each item in a pipe of $Enumerable
        [Parameter(Mandatory=$true, ParameterSetName='KeyScript, ValueName')]
        [Parameter(Mandatory=$true, ParameterSetName='KeyScript, ValueScript')]
        [System.Management.Automation.ScriptBlock]
        $KeyScript,

        [Parameter(Mandatory=$true, ParameterSetName='KeyName, ValueName')]
        [Parameter(Mandatory=$true, ParameterSetName='KeyScript, ValueName')]
        [String]
        $ValueMemberName,

        [Parameter(ParameterSetName='ValueName, ValueName')]
        [Parameter(ParameterSetName='ValueName, ValueScript')]
        [Object[]]
        $ValueArgumentList,

        # The script to extract the value from each item in a pipe of $Enumerable
        [Parameter(Mandatory=$true, ParameterSetName='KeyName, ValueScript')]
        [Parameter(Mandatory=$true, ParameterSetName='KeyScript, ValueScript')]
        [System.Management.Automation.ScriptBlock]
        $ValueScript
    )
    begin
    {
        function Get-Key {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
                [PSObject]
                $InputObject
            )
            process {
                if ($PSCmdlet.ParameterSetName -like '*KeyScript*') {
                    return $_ | ForEach-Object $KeyScript;
                }
                elseif ($KeyArgumentList) {
                    return $_ | ForEach-Object $KeyMemberName $KeyArgumentList;
                }
                else {
                    return $_ | ForEach-Object $KeyMemberName;
                }
            }
        }

        function Get-Value {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
                [PSObject]
                $InputObject
            )
            process {
                if ($PSCmdlet.ParameterSetName -like '*ValueScript*') {
                    return $_ | ForEach-Object $ValueScript;
                }
                elseif ($ValueArgumentList) {
                    return $_ | ForEach-Object $ValueMemberName $ValueArgumentList;
                }
                else {
                    return $_ | ForEach-Object $ValueMemberName;
                }
            }
        }
    }
    process
    {
        return $Enumerable | ForEach-Object `
            -begin { $HashTable = @{ }; } `
            -process { $HashTable[$(Get-Key $_)] = $(Get-Value $_); } `
            -end { return $HashTable; } ;
    }
}