function ConvertTo-HashTable
{
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName='IsKey, IsValue',     Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='IsKey, ValueMember', Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='IsKey, ValueScript', Mandatory=$true, Position=1)]
        [Switch]
        $IsKey,

        [Parameter(ParameterSetName='KeyMember, IsValue',     Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='KeyMember, ValueMember', Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='KeyMember, ValueScript', Mandatory=$true, Position=1)]
        [Alias(KeyName)]
        [ValidateNotNullOrEmpty()]
        [String]
        $KeyMemberName,

        [Parameter(ParameterSetName='KeyMember, IsValue',     Position='named')]
        [Parameter(ParameterSetName='KeyMember, ValueMember', Position='named')]
        [Parameter(ParameterSetName='KeyMember, ValueScript', Position='named')]
        [Alias(KeyArgs)]
        [Validate]
        [Object[]]
        $KeyArgumentList,

        [Parameter(ParameterSetName='KeyScript, IsValue',     Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='KeyScript, ValueMember', Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='KeyScript, ValueScript', Mandatory=$true, Position=1)]
        [Alias(GetKey)]
        [ScriptBlock]
        $KeyScript,

        [Parameter(ParameterSetName='IsKey, IsValue',     Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='KeyMember, IsValue', Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='KeyScript, IsValue', Mandatory=$true, Position=2)]
        [Switch]
        $IsValue,

        [Parameter(ParameterSetName='IsKey, ValueMember',     Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='KeyMember, ValueMember', Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='KeyScript, ValueMember', Mandatory=$true, Position=2)]
        [Alias(ValueName)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ValueMemberName,

        [Parameter(ParameterSetName='IsKey, ValueMember',     Position='named')]
        [Parameter(ParameterSetName='KeyMember, ValueMember', Position='named')]
        [Parameter(ParameterSetName='KeyScript, ValueMember', Position='named')]
        [Alias(ValueArgs)]
        [Object[]]
        $ValueArgumentList,

        [Parameter(ParameterSetName='IsKey, ValueScript',     Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='KeyMember, ValueScript', Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='KeyScript, ValueScript', Mandatory=$true, Position=2)]
        [Alias(GetValue)]
        [ScriptBlock]
        $ValueScript,

        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position='named')]
        $InputObject
    )
    begin
    {
        #region DefineHelperFunctions
        filter Get-Key {
            if ($IsKey) {
                return $_;
            }
            elseif ($PSCmdlet.ParameterSetName -like '*KeyScript*') {
                return $_ | ForEach-Object $KeyScript;
            }
            elseif ($KeyArgumentList) {
                return $_ | ForEach-Object $KeyMemberName $KeyArgumentList;
            }
            else {
                return $_ | ForEach-Object $KeyMemberName;
            }
        }

        filter Get-Value {
            if ($IsKey) {
                return $_;
            }
            elseif ($PSCmdlet.ParameterSetName -like '*ValueScript*') {
                return $_ | ForEach-Object $ValueScript;
            }
            elseif ($ValueArgumentList) {
                return $_ | ForEach-Object $ValueMemberName $ValueArgumentList;
            }
            else {
                return $_ | ForEach-Object $ValueMemberName;
            }
        }
        #endregion DefineHelperFunctinos

        $HashTable = @{ };
    }
    process
    {
        $Key = $_ | Get-Key;
        $Value = $_ | Get-Value;
        $HashTable[$Key] = $Value;
    }
    end
    {
        return $HashTable;
    }
}