<#
.SYNOPSIS
    Converts a pipeline to a hash table.
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
    Whether the returned hash table will have the Ordered attribute. If so, then
    the underlying type is actuall [System.Collections.Specialized.OrderedDictionary].
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
        [Parameter(ParameterSetName='KeyName, ValName', Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='KeyName, GetVal', Mandatory=$true, Position=1)]
        [Alias('KeyName')]
        [ValidateNotNullOrEmpty()]
        [String]
        $KeyMemberName,

        [Parameter(ParameterSetName='KeyName, ValName', Position=0)]
        [Parameter(ParameterSetName='KeyName, GetVal', Position=0)]
        [Alias('KeyArgs')]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $KeyArgumentList,

        [Parameter(ParameterSetName='GetKey, ValName', Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName='GetKey, GetVal', Mandatory=$true, Position=1)]
        [Alias('GetKey')]
        [ValidateNotNull()]
        [ScriptBlock]
        $KeyScript,

        [Parameter(ParameterSetName='KeyName, ValName', Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='GetKey, ValName', Mandatory=$true, Position=2)]
        [Alias('ValName')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ValueMemberName,

        [Parameter(ParameterSetName='KeyName, ValName', Position=0)]
        [Parameter(ParameterSetName='GetKey, ValName', Position=0)]
        [Alias('ValArgs')]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $ValueArgumentList,

        [Parameter(ParameterSetName='KeyName, GetVal', Mandatory=$true, Position=2)]
        [Parameter(ParameterSetName='GetKey, GetVal', Mandatory=$true, Position=2)]
        [Alias('GetVal')]
        [ValidateNotNull()]
        [ScriptBlock]
        $ValueScript,

        [Parameter(Position=0)]
        [Switch]
        $Ordered,

        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='KeyName, ValName')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='KeyName, GetVal')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='GetKey, ValName')]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0, ParameterSetName='GetKey, GetVal')]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        $InputObject
    )
    begin
    {
        #region Define Get-Key
        if ($KeyScript) {
            filter Get-Key { $_ | ForEach-Object $KeyScript }
        }
        elseif ($KeyArgumentList) {
            filter Get-Key { $_ | ForEach-Object $KeyMemberName -ArgumentList $KeyArgumentList }
        }
        else {
            filter Get-Key { $_ | ForEach-Object $KeyMemberName }
        }
        #endregion Define Get-Key

        #region Define Get-Value
        if ($ValueScript) {
            filter Get-Value { $_ | ForEach-Object $ValueScript }
        }
        elseif ($ValueArgumentList) {
            filter Get-Value { $_ | ForEach-Object $ValueMemberName -ArgumentList $ValueArgumentList }
        }
        else {
            filter Get-Value { $_ | ForEach-Object $ValueMemberName }
        }
        #endregion Define Get-Value

        #region Initialize HashTable
        if ($Ordered) {
            [HashTable] $HashTable = [Ordered] @{ };
        }
        else {
            [HashTable] $HashTable = @{ };
        }
        #endregion Initialize HashTable
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