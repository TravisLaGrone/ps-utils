<#
.SYNOPSIS
    Converts a pipeline to a hash table.
.PARAMETER Object
    Equivalent to `-KeyMemberName 'ToString' -IsValue`. Intended for use with
    raw objects. Aliased as 'Default'.
.PARAMETER Property
    Equivalent to `-KeyMemberName 'Name' -ValueMemberName 'Value'`. Intended for
    use with a PSPropertySet pipeline of PSPropertyInfo objects. Aliased as
    'NameValue'.
.PARAMETER Entry
    Equivalent to `-KeyMemberName 'Key' -ValueMemberName 'Value'`. Intended for
    use with an IDictionaryEnumerator pipeline of DictionaryEntry objects.
    Aliased as 'KeyValue'.
.PARAMETER IsKey
    Whether to use each object itself as the key.
.PARAMETER KeyMemberName
    The name of the object member whose value to use as the key. May be either
    a property or a method. If a method, the method is invoked and the return
    result is used as the key. Aliased as 'KeyName'.
.PARAMETER KeyArgumentList
    The (optional) array of arguments to pass to the member key member method.
    Only applicable if the key member is a method. Aliased as 'KeyArgs'.
.PARAMETER KeyScript
    The delay-bind script block with which to extract the key from the piped
    object. See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_script_blocks?view=powershell-6#using-delay-bind-script-blocks-with-parameters
    Aliased as 'GetKey'.
.PARAMETER IsValue
    Whether to use each value itself as the key.
.PARAMETER ValueMemberName
    The name of the object member whose value to use as the value. May be either
    a property or a method. If a method, the method is invoked and the return
    result is used as the value. Aliased as 'ValueName'.
.PARAMETER ValueArgumentList
    The (optional) array of arguments to pass to the member value member method.
    Only applicable if the value member is a method. Aliased as 'ValueArgs'.
.PARAMETER ValueScript
    The delay-bind script block with which to extract the value from the piped
    object. See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_script_blocks?view=powershell-6#using-delay-bind-script-blocks-with-parameters
    Aliased as 'GetValue'.
.INPUTS
    Object
        The pipeline of objects from which to build a hash table.
.OUTPUTS
    HashTable
        A hash table built from the pipeline of objects.
#>
function ConvertTo-HashTable
{
    [CmdletBinding(DefaultParameterSetName='ToStringKey, ObjectValue')]
    param
    (
        [Parameter(ParameterSetName='ToStringKey, ObjectValue', Mandatory=$true, Position=0)]
        [Alias('Default', 'ToStringObject')]
        [ValidateSet($true)]
        [Switch]
        $Object = $true,

        [Parameter(ParameterSetName='NameKey, ValueValue')]
        [Alias('PSPropertyInfo', 'NameValue')]
        [ValidateSet($true)]
        [Switch]
        $Property,

        [Parameter(ParameterSetName='KeyKey, ValueValue')]
        [Alias('DictionaryEntry', 'KeyValue')]
        [ValidateSet($true)]
        [Switch]
        $Entry,

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
            if ($Default) {
                return "$_";
            }
            elseif ($Property) {
                return $_.Name;
            }
            elseif ($Entry) {
                return $_.Key;
            }
            elseif ($IsKey) {
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
            if ($Default) {
                return $_;
            }
            elseif ($Property) {
                return $_.Value;
            }
            elseif ($Entry) {
                return $_.Value;
            }
            elseif ($IsKey) {
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
        #endregion DefineHelperFunctions

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