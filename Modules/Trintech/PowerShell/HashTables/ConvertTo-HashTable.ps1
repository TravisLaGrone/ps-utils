<#
.SYNOPSIS
    Converts a pipeline to a hash table.
.PARAMETER IsKey
    Whether to use each object itself as the key.
.PARAMETER KeyMemberName
    The name of the object member whose value to use as the key. May be either
    a property or a method. If a method, the method is invoked and the return
    result is used as the key.
.PARAMETER KeyArgumentList
    The (optional) array of arguments to pass to the member key member method.
    Only applicable if the key member is a method.
.PARAMETER KeyScript
    The delay-bind script block with which to extract the key from the piped
    object. See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_script_blocks?view=powershell-6#using-delay-bind-script-blocks-with-parameters
.PARAMETER IsValue
    Whether to use each value itself as the key.
.PARAMETER ValueMemberName
    The name of the object member whose value to use as the value. May be either
    a property or a method. If a method, the method is invoked and the return
    result is used as the value.
.PARAMETER ValueArgumentList
    The (optional) array of arguments to pass to the member value member method.
    Only applicable if the value member is a method.
.PARAMETER ValueScript
    The delay-bind script block with which to extract the value from the piped
    object. See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_script_blocks?view=powershell-6#using-delay-bind-script-blocks-with-parameters
.INPUTS
    Object
        The pipeline of objects from which to build a hash table.
.OUTPUTS
    HashTable
        A hash table built from the pipeline of objects.
#>
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
        [Alias('KeyName')]
        [ValidateNotNullOrEmpty()]
        [String]
        $KeyMemberName,

        [Parameter(ParameterSetName='KeyMember, IsValue',     Position=0)]
        [Parameter(ParameterSetName='KeyMember, ValueMember', Position=0)]
        [Parameter(ParameterSetName='KeyMember, ValueScript', Position=0)]
        [Alias('KeyArgs')]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $KeyArgumentList,

        [Parameter(ParameterSetName='KeyScript, IsValue',     Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='KeyScript, ValueMember', Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='KeyScript, ValueScript', Mandatory=$true, Position=1)]
        [Alias('GetKey')]
        [ValidateNotNull()]
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
        [Alias('ValueName')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ValueMemberName,

        [Parameter(ParameterSetName='IsKey, ValueMember',     Position=0)]
        [Parameter(ParameterSetName='KeyMember, ValueMember', Position=0)]
        [Parameter(ParameterSetName='KeyScript, ValueMember', Position=0)]
        [Alias('ValueArgs')]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $ValueArgumentList,

        [Parameter(ParameterSetName='IsKey, ValueScript',     Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='KeyMember, ValueScript', Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='KeyScript, ValueScript', Mandatory=$true, Position=2)]
        [Alias('GetValue')]
        [ValidateNotNull()]
        [ScriptBlock]
        $ValueScript,

        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0)]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
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