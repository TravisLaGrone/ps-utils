# TODO test New-Dictionary
function New-Dictionary {
    [CmdletBinding(DefaultParameterSetName='KeyInput, ValueInput', PositionalBinding=$false)]
    [OutputType('System.Collections.IDictionary')]
    param (
        [Parameter(ParameterSetName='KeyInput, ValueInput')]
        [Parameter(ParameterSetName='KeyInput, ValueLiteral')]
        [Parameter(ParameterSetName='KeyInput, ValueProperty')]
        [Parameter(ParameterSetName='KeyInput, ValueMethod')]
        [Parameter(ParameterSetName='KeyInput, ValueScript')]
        [Switch]
        [ValidateSet($null, $true)]
        [Alias('KeyInput', 'AsKey')]
        $KeyIsInputObject,

        [Parameter(ParameterSetName='KeyLiteral, ValueInput', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyLiteral, ValueLiteral', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyLiteral, ValueProperty', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyLiteral, ValueMethod', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyLiteral, ValueScript', Mandatory, Position=1)]
        [Object]
        [ValidateNotNull()]
        [Alias('KeyConstant')]
        $KeyLiteralObject,

        [Parameter(ParameterSetName='KeyProperty, ValueInput', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyProperty, ValueLiteral', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyProperty, ValueProperty', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyProperty, ValueMethod', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyProperty, ValueScript', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyMethod, ValueInput', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyMethod, ValueLiteral', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyMethod, ValueProperty', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyMethod, ValueMethod', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyMethod, ValueScript', Mandatory, Position=1)]
        [String]
        [ValidateNotNullOrEmpty()]
        [Alias('KeyName')]
        $KeyMemberName,

        [Parameter(ParameterSetName='KeyMethod, ValueInput', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyMethod, ValueLiteral', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyMethod, ValueProperty', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyMethod, ValueMethod', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyMethod, ValueScript', Mandatory, Position=2)]
        [Array]
        [ValidateNotNull()]
        [Alias('KeyArgs')]
        $KeyArgumentList,

        [Parameter(ParameterSetName='KeyScript, ValueInput', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyScript, ValueLiteral', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyScript, ValueProperty', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyScript, ValueMethod', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyScript, ValueScript', Mandatory, Position=1)]
        [ScriptBlock]
        [ValidateNotNull()]
        [Alias('KeyScript', 'GetKey')]
        $KeyProcessScript,

        [Parameter(ParameterSetName='KeyInput, ValueInput')]
        [Parameter(ParameterSetName='KeyLiteral, ValueInput')]
        [Parameter(ParameterSetName='KeyProperty, ValueInput')]
        [Parameter(ParameterSetName='KeyMethod, ValueInput')]
        [Parameter(ParameterSetName='KeyScript, ValueInput')]
        [Switch]
        [ValidateSet($null, $true)]
        [Alias('ValueLiteral', 'AsValue')]
        $ValueIsInputObject,

        [Parameter(ParameterSetName='KeyInput, ValueLiteral', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyLiteral, ValueLiteral', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyProperty, ValueLiteral', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyMethod, ValueLiteral', Mandatory, Position=3)]
        [Parameter(ParameterSetName='KeyScript, ValueLiteral', Mandatory, Position=2)]
        [Object]
        [ValidateNotNull()]
        [Alias('ValueConstant')]
        $ValueLiteralObject,

        [Parameter(ParameterSetName='KeyInput, ValueProperty', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyLiteral, ValueProperty', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyProperty, ValueProperty', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyMethod, ValueProperty', Mandatory, Position=3)]
        [Parameter(ParameterSetName='KeyScript, ValueProperty', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyInput, ValueMethod', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyLiteral, ValueMethod', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyProperty, ValueMethod', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyMethod, ValueMethod', Mandatory, Position=3)]
        [Parameter(ParameterSetName='KeyScript, Valuemethod', Mandatory, Position=2)]
        [String]
        [ValidateNotNullOrEmpty()]
        [Alias('ValueName')]
        $ValueMemberName,

        [Parameter(ParameterSetName='KeyInput, ValueMethod', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyLiteral, ValueMethod', Mandatory, Position=3)]
        [Parameter(ParameterSetName='KeyProperty, ValueMethod', Mandatory, Position=3)]
        [Parameter(ParameterSetName='KeyMethod, ValueMethod', Mandatory, Position=4)]
        [Parameter(ParameterSetName='KeyScript, ValueMethod', Mandatory, Position=3)]
        [Array]
        [ValidateNotNull()]
        [Alias('ValueArgs')]
        $ValueArgumentList,

        [Parameter(ParameterSetName='KeyInput, ValueScript', Mandatory, Position=1)]
        [Parameter(ParameterSetName='KeyLiteral, ValueScript', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyProperty, ValueScript', Mandatory, Position=2)]
        [Parameter(ParameterSetName='KeyMethod, ValueScript', Mandatory, Position=3)]
        [Parameter(ParameterSetName='KeyScript, ValueScript', Mandatory, Position=2)]
        [ScriptBlock]
        [ValidateNotNull()]
        [Alias('ValueScript', 'GetValue')]
        $ValueProcessScript,

        [Parameter()]
        [OnDuplicateActions]
        [ValidateNotNull()]
        [Alias('OnDuplicateKey')]
        $DuplicateKeyAction = [OnDuplicateActions]::ThrowException,

        [Parameter(ValueFromRemainingArguments)]  # ValueFromRemainingArguments to allow it to emulate a positional parameter in the final position
        [ScriptBlock]
        [ValidateNotNull()]  # although, $DuplicateKeyScript is ignored unless $DuplicateKeyAction is [OnDuplicateActions]::InvokeCommand
        [ValidateCount(1,1)]  # necessary to validate that not multinary because ValueFromRemainingArguments
        [Alias('ResolveDuplicate')]
        $DuplicateKeyScript,

        [Parameter(ValueFromPipeline)]
        [Object]
        $InputObject
    )
    begin {
        $SplitParameterSetName = $PSCmdlet.ParameterSetName.Split(', ')
        $KeyParameterSetName = $SplitParameterSetName[0]
        $ValueParameterSetName = $SplitParameterSetName[1]

        $ToKey = switch($KeyParameterSetName) {
            KeyInput {
                { $_ }
            }
            KeyLiteral {
                { $KeyLiteralObject }
            }
            KeyProperty {
                $KeyMemberName
            }
            KeyMethod {
                @($KeyMemberName, $KeyArgumentList)
            }
            KeyScript {
                $KeyProcessScript
            }
        }

        $ToValue = switch($ValueParameterSetName) {
            ValueInput {
                { $_ }
            }
            ValueLiteral {
                { $ValueLiteralObject }
            }
            ValueProperty {
                $ValueMemberName
            }
            ValueMethod {
                @($ValueMemberName, $ValueArgumentList)
            }
            ValueScript {
                $ValueProcessScript
            }
        }

        $Duplicates = @{ }  # used with [OnDuplicateActions]::ConstructArray
        $ReduceDuplicates = switch($DuplicateKeyAction) {
            ThrowException {
                {
                    param($OldEntry, $NewEntry)
                    throw "Error, duplicate keys: @{ $($OldEntry.Key) = $($OldValue.Key) }, @{ $($NewEntry.Key) = $($NewEntry.Value) } "
                }
            }
            KeepFirst {
                {
                    param($OldEntry, $NewEntry)
                    return $OldEntry
                }
            }
            KeepLast {
                {
                    param($OldEntry, $NewEntry)
                    return $NewEntry
                }
            }
            KeepLesser {
                {
                    param($OldEntry, $NewEntry)
                    return if ($OldEntry.Key -le $NewEntry.key) {
                        $OldEntry
                    } else {
                        $NewEntry
                    }
                }
            }
            KeepGreater {
                {
                    param($OldEntry, $newEntry)
                    return if ($OldEntry.Key -gt $NewEntry.key) {
                        $OldEntry
                    } else {
                        $NewEntry
                    }
                }
            }
            Add {
                {
                    param($OldEntry, $newEntry)
                    return New-Object System.Collections.DictionaryEntry($OldEntry.Key, $OldEntry.Value + $NewEntry.Value)
                }
            }
            ConstructArray {
                $block = {
                    param($OldEntry, $newEntry)
                    $Key = $NewEntry.Key
                    $Value = $NewEntry.Value
                    if (-not $Duplicates.ContainsKey($Key)) {
                        $Duplicates[$Key] = New-Object System.Collections.ArrayList
                    }
                    $Duplicates[$Key].Add($Value) > $nul  # redirect to suppress outputting the position added
                    return $OldEntry
                }
                return $block.GetNewClosure()  # closure because accesses $Duplicates
            }
            InvokeCommand {
                $DuplicateKeyScript
            }
        }
    end {
        $Dictionary = New-Object System.Collections.Hashtable
        foreach ($Object in $Input) {
            $Key = $Object | ForEach-Object @ToKey
            $Value = $Object | ForEach-Object @ToValue
            if ($Dictionary.ContainsKey($Key)) {
                $ReducedEntry = Invoke-Command $ReduceDuplicates -ArgumentList @(
                    New-Object System.Collections.DictionaryEntry($Key, $Dictionary[$Key])
                    New-Object System.Collections.DictionaryEntry($Key, $Value)
                )
                $Dictionary.Remove($Key)
                $Key = $ReducedEntry.Key
                $Value = $ReducedEntry.Value
            }
            $Dictionary.Add($Key, $Value)
        }
        foreach ($Key in $Duplicates.Keys) {  # finalize duplicates (only if $DuplicateKeyAction -eq [OnDuplicateActions]::ConstructArray)
            $OrigVal = $Dictionary[$Key]  # type: Object
            $DupVals = $Duplicates[$Key]  # type: IList
            $Values = @(, $OrigVal) + $DupVals  # type: Object[]
            $Dictionary.Remove($Key)
            $Dictionary.Add($Key, $Values)
        }
        return $Dictionary
    }
}