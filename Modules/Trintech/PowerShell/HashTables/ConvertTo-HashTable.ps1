<#
.SYNOPSIS
    Converts a pipeline to a hash table.
.PARAMETER InputObjectIsKey
    Equivalent to `-KeyScript { $_ }`. Aliased as 'IsKey'.
.PARAMETER KeyMemberName
    Equivalent to `-KeyScript { $_ | ForEach-Object $KeyMemberName }`.
    Aliased as 'KeyName'.
.PARAMETER KeyArgumentList
    The (optional) array of arguments to pass to the member key member method.
    Only applicable if the key member is a method. Equivalent to
    `-KeyScript $KeyMemberName $KeyArgumentList`. Aliased as 'KeyArgs'.
.PARAMETER KeyScript
    The delay-bind script block with which to extract the key from the piped
    object. See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_script_blocks?view=powershell-6#using-delay-bind-script-blocks-with-parameters
    Aliased as 'GetKey'.
.PARAMETER InputObjectIsValue
    Equivalent to `-ValueScript { $_ }`. Aliased as 'IsValue'.
.PARAMETER ValueMemberName
    Equivalent to `-ValueScript { $_ | ForEach-Object $ValueMemberName }`.
    Aliased as 'ValName'.
.PARAMETER ValueArgumentList
    The (optional) array of arguments to pass to the member value member method.
    Only applicable if the value member is a method. Equivalent to
    `-ValueScript $ValueMemberName $ValueArgumentList`. Aliased as 'ValArgs'.
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
#>
function ConvertTo-HashTable
{
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName='IsKey, IsValue',     Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='IsKey, ValueMember', Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='IsKey, ValueScript', Mandatory=$true, Position=1)]
        [Alias('IsKey')]
        [ValidateSet($true)]
        [Switch]
        $InputObjectIsKey,

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
        [Alias('IsValue')]
        [ValidateSet($true)]
        [Switch]
        $InputObjectIsValue,

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
            if ($InputObjectIsKey) {
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
            if ($InputObjectIsValue) {
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
            [HashTable] $HashTable = [Ordered] @{ };
        }
        else {
            [HashTable] $HashTable = @{ };
        }
        #endregion Initialize-HashTable
    }
    process
    {
        $Key = $InputObject | Get-Key;
        $Value = $InputObject | Get-Value;
        $HashTable[$Key] = $Value;
    }
    end
    {
        return $HashTable;
    }
}