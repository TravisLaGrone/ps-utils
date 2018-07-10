<#
.SYNOPSIS
    Converts a pipeline to a hash table.
.PARAMETER FromPSPropertyInfo
    Equivalent to `-KeyMemberName 'Name' -ValueMemberName 'Value'`. Intended for
    use with a PSPropertySet pipeline of PSPropertyInfo objects. Aliased as
    'FromProperty'.
.PARAMETER FromDictionaryEntry
    Equivalent to `-KeyMemberName 'Key' -ValueMemberName 'Value'`. Intended for
    use with an IDictionaryEnumerator pipeline of DictionaryEntry objects, which
    may be obtained from a HashTable by invoking its GetEnumerator method.
    Aliased as 'FromEntry'.
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
    result is used as the value. Aliased as 'ValName'.
.PARAMETER ValueArgumentList
    The (optional) array of arguments to pass to the member value member method.
    Only applicable if the value member is a method. Aliased as 'ValArgs'.
.PARAMETER ValueScript
    The delay-bind script block with which to extract the value from the piped
    object. See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_script_blocks?view=powershell-6#using-delay-bind-script-blocks-with-parameters
    Aliased as 'GetVal'.
.PARAMETER Ordered
    Whether the returned hash table will have the Ordered attribute.
.INPUTS
    Object
        The pipeline of objects from which to build a hash table.
.OUTPUTS
    HashTable, System.Collections.Specialized.OrderedDictionary
        An associative collection built by collecting the pipeline. The type is
        HashTable unless the Ordered flag has been to $true, in which case the
        type is OrderedDictionary.
.NOTES
    If no parameters are specified (other than the pipeline parameter), then the
    keys are mapped to the string representation of their respective input objects,
    and the values are the objects unchanged. Key stringification is performed
    using `"$_"`, not `$_.ToString()`; as such, null values are mapped to empty
    strings.
#>
function ConvertTo-HashTable
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    param
    (
        [Parameter(ParameterSetName='FromPSPropertyInfo', Mandatory=$true, Position=0)]
        [Alias('FromProperty')]
        [ValidateSet($true)]
        [Switch]
        $FromPSPropertyInfo,

        [Parameter(ParameterSetName='FromDictionaryEntry', Mandatory=$true, Position=0)]
        [Alias('FromEntry')]
        [ValidateSet($true)]
        [Switch]
        $FromDictionaryEntry,

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
        [Alias('ValName')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ValueMemberName,

        [Parameter(ParameterSetName='IsKey, ValueMember',     Position=0)]
        [Parameter(ParameterSetName='KeyMember, ValueMember', Position=0)]
        [Parameter(ParameterSetName='KeyScript, ValueMember', Position=0)]
        [Alias('ValArgs')]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $ValueArgumentList,

        [Parameter(ParameterSetName='IsKey, ValueScript',     Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='KeyMember, ValueScript', Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='KeyScript, ValueScript', Mandatory=$true, Position=2)]
        [Alias('GetVal')]
        [ValidateNotNull()]
        [ScriptBlock]
        $ValueScript,

        [Parameter(Position=0)]
        [Switch]
        $Ordered,

        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='Default')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='FromPSPropertyInfo')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='FromDictionaryEntry')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='IsKey, IsValue')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='IsKey, ValueMember')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='IsKey, ValueScript')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='KeyMember, IsValue')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='KeyMember, ValueMember')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='KeyMember, ValueScript')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='KeyScript, IsValue')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='KeyScript, ValueMember')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='KeyScript, ValueScript')]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        $InputObject
    )
    begin
    {
        #region Define-HelperFunctions
        filter Get-Key {
            if ($PSCmdlet.ParameterSetName -eq 'Default') {
                return "$_";
            }
            elseif ($FromPSPropertyInfo) {
                return $_.Name;
            }
            elseif ($FromDictionaryEntry) {
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
            if ($PSCmdlet.ParameterSetName -eq 'Default') {
                return $_;
            }
            elseif ($FromPSPropertyInfo) {
                return $_.Value;
            }
            elseif ($FromDictionaryEntry) {
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
        #endregion Define-HelperFunctions

        #region Initialize-HashTable
        if ($Ordered) {
            $HashTable = [Ordered] @{ };
        }
        else {
            $HashTable = @{ };
        }
        #endregion Initialize-HashTable
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