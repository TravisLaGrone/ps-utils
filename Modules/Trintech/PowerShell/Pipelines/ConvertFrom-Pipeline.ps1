<#
.SYNOPSIS
    .
.PARAMETER KeyProcess
    The delay-bind script block with which to extract the key from each object
    in the pipeline. See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_script_blocks?view=powershell-6#using-delay-bind-script-blocks-with-parameters
    Aliased as 'KeyGetter'.
.PARAMETER ValueProcess
    The delay-bind script block with which to extract the value from each object
    in the pipeline. See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_script_blocks?view=powershell-6#using-delay-bind-script-blocks-with-parameters
    Aliased as 'ValueGetter'
.PARAMETER Ordered
    Whether the returned hash table will have the Ordered attribute. If so, then
    the underlying type is actuall [System.Collections.Specialized.OrderedDictionary].
.INPUTS
    .
.OUTPUTS
    .
#>
function ConvertFrom-Pipeline
{
    [CmdletBinding(PositionalBinding=$false, DefaultParameterSetName='ToArray')]
    param
    (
        #region ToArray
        [Parameter(ParameterSetName='[ToArray], [Force]')]
        [ValidateSet($true)]
        [Switch]
        $ToArray,

        [Parameter(ParameterSetName='[ToArray], [Force]')]
        [Switch]
        $Force,
        #endregion ToArray

        #region ToHashTable
        [Parameter(ParameterSetName='[ToHashTable], Key')]
        [Parameter(ParameterSetName='[ToHashTable], Value')]
        [Parameter(ParameterSetName='[ToHashTable], Key, Value')]
        [ValidateSet($true)]
        [Switch]
        $ToHashTable,

        [Parameter(ParameterSetName='[ToHashTable], Key')]
        [Parameter(ParameterSetName='[ToHashTable], Value')]
        [Parameter(ParameterSetName='[ToHashTable], Key, Value')]
        [Switch]
        $Ordered,

        [Parameter(ParameterSetName='[ToHashTable], Key', Mandatory=$true)]
        [Parameter(ParameterSetName='[ToHashTable], Key, Value', Mandatory=$true, Position=1)]
        [Alias('KeyGetter')]
        [ValidateNotNull()]
        [ScriptBlock]
        $KeyProcess,

        # COMBAK KeyName alternate parameter
        # COMBAK KeyLiteral alternate parameter

        [Parameter(ParameterSetName='[ToHashTable], Value', Mandatory=$true)]
        [Parameter(ParameterSetName='[ToHashTable], Key, Value', Mandatory=$true, Position=2)]
        [Alias('ValueGetter')]
        [ValidateNotNull()]
        [ScriptBlock]
        $ValueProcess,

        # COMBAK ValueName alternate parameter
        # COMBAK ValueLiteral alternate parameter

        #endregion ToHashTable

        #region ToString
        [Parameter(ParameterSetName='ToString, [Delimiter]', Mandatory=$true)]
        [Parameter(ParameterSetName='[ToString], Delimiter')]
        [ValidateSet($true)]
        [Switch]
        $ToString,

        [Parameter(ParameterSetName='ToString, [Delimiter]', Position=1)]
        [Parameter(ParameterSetName='[ToString], Delimiter', Mandatory=$true, Position=1)]
        [ValidateNotNull()]
        [AllowEmptyString()]
        [String]
        $Delimiter = '',
        #endregion ToString

        #region ToCollection

        # TODO ToCollection parameters
        # Constructor: () => TCollection (alternative: CollectionType[Name])
        # Collector: TCollection, TItem => TCollection
        # Combiner: TCollection, TCollection => TCollection

        #endregion ToCollection

        #region ToMeasure

        # TODO ToMeasure parameters  (...but does this really belong in this function?)
        # IdentityValue: TItem
        # ...

        #endregion ToMeasure

        #region ToPipeline

        # TODO ToPipeline parameters  (meh... this doesn't really belong in this function)
        # Fold: ...
        # Scan: ...

        #endregion ToPipeline

        # A delay-bind script block that will be invoked with the converted pipeline as its one-and-only unnamed *pipeline* item argument
        [Parameter()]
        [ValidateNotNull()]
        [ScriptBlock]
        $AndThen,

        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        $InputObject
    )
    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'ToArray') {
            $Converted = @($Input)
            if ($Force -and $Converted.Count -le 1) {
                $Converted = $(, $Converted)
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ToHashTable') {
            #region Initialize Hash Table
            if ($Ordered) {
                $Converted = [Ordered] @{ };
            } else {
                $Converted = @{ };
            }
            #endregion Initialize Hash Table

            #region Populate Hash Table
            foreach ($Item in $Input) {
                #region Get Key
                if ($ProcessKey) {
                    $Key = $Item | ForEach-Object $ProcessKey
                } else {
                    $Key = $Item
                }
                #endregion Get Key

                #region Get Value
                if ($ProcessValue) {
                    $Value = $Item | ForEach-Object $ProcessValue
                } else {
                    $Value = $Item
                }
                # TODO Get Value
                #endregion Get Value

                $Converted[$Key] = $Value;
            }
            #endregion Populate Hash Table
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ToString') {
            $Converted = @($Input) -join $Delimiter
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ToCollection') {
            # TODO ToCollection logic
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ToMeasure') {
            # TODO ToMeasure logic
        }
        else {
            throw "Unrecognized parameter set: $($PSCmdlet.ParameterSetName)"
        }

        if ($AndThen) {
            $Converted = @(, $Converted) | ForEach-Object $AndThen
        }

        return $Converted;
    }
}