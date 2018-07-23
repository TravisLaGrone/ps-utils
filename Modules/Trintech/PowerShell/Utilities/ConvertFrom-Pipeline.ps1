<#
.SYNOPSIS
    Converts a pipeline to another data structure.
.DESCRIPTION
    Converts a pipeline to another data structure. The pipeline as a whole is
    converted, not each element; i.e. this function "collects" the elements of
    a pipeline.
.PARAMETER ToArray
    Indicates that the pipeline will be converted to an array.
.PARAMETER ToHashTable
    Indicates that the pipeline will be converted to a hash table.
.PARAMETER Ordered
    Indicates that the returned hash table will have the Ordered attribute. If so, then
    its underlying type is actually System.Collections.Specialized.OrderedDictionary.
.PARAMETER KeyScript
    The delay-bind script block with which to extract the key from each object
    in the pipeline. See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_script_blocks?view=powershell-6#using-delay-bind-script-blocks-with-parameters
    Aliased as 'GetKey'.
.PARAMETER ValueScript
    The delay-bind script block with which to extract the value from each object
    in the pipeline. See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_script_blocks?view=powershell-6#using-delay-bind-script-blocks-with-parameters
    Aliased as 'GetValue'.
.PARAMETER ToString
    Indicates that the pipeline will be converted to a string.
.PARAMETER Delimiter
    The separator with which to join each element when converting the pipeline
    to a string.
.PARAMETER Prefix
    The prefix to prepend to the result of the converting the pipeline to a string.
.PARAMETER Suffix
    The suffix to append to the result of converting the pipeline to a string.
.PARAMETER ToCollection
    Indicates that the pipeline will be converted to an arbitrary collection.
.PARAMETER Constructor
    The parameter-less script block that shall return a new instance of the
    collection type to which the pipeline will be collected. May be invoked
    multiple times if parallelization is used. Aliased as "NewCollection".
.PARAMETER Collector
    The delay-bind script block that shall add an element to a collection and
    return the resulting collection. It takes one parameter, "Collection",
    which is the collection to which an element--passed via pipeline--shall be
    added. Aliased as "AddElement".
.INPUTS
    Object
        The object that shall constitute one element, entry, or substring in the
        process of converting the pipeline to another structure.
.OUTPUTS
    Array, HashTable, System.Collections.Specialized.OrderedDictionary, String
        The converted pipeline.
#>
function ConvertFrom-Pipeline
{
    [CmdletBinding(PositionalBinding=$false, DefaultParameterSetName='ToArray')]
    param
    (
        #region ToArray
        [Parameter(ParameterSetName='ToArray')]
        [ValidateSet($true)]
        [Switch]
        $ToArray,
        #endregion ToArray

        #region ToHashTable
        [Parameter(ParameterSetName='ToHashTable')]
        [ValidateSet($true)]
        [Switch]
        $ToHashTable,

        [Parameter(ParameterSetName='ToHashTable', Mandatory=$true, Position=1)]
        [Alias('GetKey')]
        [ValidateNotNull()]
        [ScriptBlock]
        $KeyScript,

        # COMBAK KeyName alternate parameter
        # COMBAK KeyLiteral alternate parameter

        [Parameter(ParameterSetName='ToHashTable', Mandatory=$true, Position=2)]
        [Alias('GetValue')]
        [ValidateNotNull()]
        [ScriptBlock]
        $ValueScript,

        [Parameter(ParameterSetName='ToHashTable')]
        [Switch]
        $Ordered,

        [Parameter(ParameterSetName='ToHashTable')]
        [ValidateNotNull()]
        [OnDuplicateKey]
        $OnDuplicateKey = 'KeepFirst',

        # COMBAK ValueName alternate parameter
        # COMBAK ValueLiteral alternate parameter

        #endregion ToHashTable

        #region ToString
        [Parameter(ParameterSetName='ToString')]
        [ValidateSet($true)]
        [Switch]
        $ToString,

        [Parameter(ParameterSetName='ToString', Position=1)]
        [Alias('Separator')]
        [ValidateNotNull()]
        [AllowEmptyString()]
        [String]
        $Delimiter = '',

        [Parameter(ParameterSetName='ToString')]
        [Alias('Prepend')]
        [ValidateNotNull()]
        [AllowEmptyString()]
        [String]
        $Prefix = '',

        [Parameter(ParameterSetName='ToString')]
        [Alias('Append')]
        [ValidateNotNull()]
        [AllowEmptyString()]
        [String]
        $Suffix = '',
        #endregion ToString

        #region ToCollection
        [Parameter(ParameterSetName='ToCollection')]
        [ValidateSet($true)]
        [Switch]
        $ToCollection,

        [Parameter(ParameterSetName='ToCollection', Mandatory, Position=1)]
        [Alias('NewCollection')]
        [ValidateNotNull()]
        [ScriptBlock]
        $Constructor,

        [Parameter(ParameterSetName='ToCollection', Mandatory, Position=2)]
        [Alias('AddElement')]
        [ValidateNotNull()]
        [ScriptBlock]
        $Collector,
        #endregion ToCollection

        [Parameter(ParameterSetName='ToArray', ValueFromPipeline=$true, Mandatory=$true)]
        [Parameter(ParameterSetName='ToHashTable', ValueFromPipeline=$true, Mandatory=$true)]
        [Parameter(ParameterSetName='ToString', ValueFromPipeline=$true, Mandatory=$true)]
        [Parameter(ParameterSetName='ToCollection', ValueFromPipeline=$true, Mandatory=$true)]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        $InputObject
    )
    end
    {
        if ($PSCmdlet.ParameterSetName -like '*ToArray*') {
            $Converted = @($Input)
        }
        elseif ($PSCmdlet.ParameterSetName -like '*ToHashTable*') {
            if ($Ordered) {
                $Converted = [Ordered] @{ };
            } else {
                $Converted = @{ };
            }

            foreach ($Item in $Input) {
                $Key = $Item | ForEach-Object $KeyScript
                $Value = $Item | ForEach-Object $ValueScript
                if (-not $Converted.ContainsKey($Key)) {
                    $Converted.Add($Key, $Value)
                } else {
                    switch ($OnDuplicateKey) {
                        KeepFirst { }
                        KeepLast { $Converted[$Key] = $Value }
                        ThrowError { throw "Error, duplicate key `"$Key`"" }
                        default { throw "Error, unrecognize value for OnDuplicateKey: `"$OnDuplicateKey`"" }
                    }
                }
            }
        }
        elseif ($PSCmdlet.ParameterSetName -like '*ToString*') {
            $Converted = $Prefix + (@($Input) -join $Delimiter) + $Suffix
        }
        elseif ($PSCmdlet.ParameterSetName -like '*ToCollection*') {
            $Converted = Invoke-Command $Constructor
            $Input | ForEach-Object $Collector -ArgumentList $Converted
        }
        else {
            throw "Unrecognized parameter set: $($PSCmdlet.ParameterSetName)"
        }

        return $Converted;
    }
}

enum OnDuplicateKey { KeepFirst; KeepLast; ThrowError }