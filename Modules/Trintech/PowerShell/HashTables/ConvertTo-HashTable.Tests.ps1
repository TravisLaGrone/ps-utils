$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "ConvertTo-HashTable" {
    BeforeAll {
        enum KeyParameter { InputObjectIsKey; KeyMemberName; KeyArgumentList; KeyScript }
        enum ValueParameter { InputObjectIsValue; ValueMemberName; ValueArgumentList; ValueScript }

        #region Create-ParameterSets
        $PARAMETER_SETS = New-Object -TypeName 'System.Collections.ArrayList'
        foreach ($KeyParam in [KeyParameter].GetEnumNames() ) {
            if ($KeyParam -eq 'KeyArgumentList') {
                $KeyParams = @('KeyMemberName', $KeyParam)
            } else {
                $KeyParams = @($KeyParam)
            }

            foreach ($ValueParam in [ValueParameter].GetEnumNames() ) {
                if ($ValueParam -eq 'ValueArgumentList') {
                    $ValueParams = @('ValueMemberName', $ValueParam)
                } else {
                    $ValueParams = @($ValueParam)
                }

                $ParamSet = $KeyParams + $ValueParams
                $PARAMETER_SETS.Add($ParamSet)
            }
        }
        #endregion Create-ParameterSets

        function Compare-HashTable([HashTable]$A, [HashTable]$B) {
            $KeysB = [System.Collections.ArrayList] $B.Keys
            foreach ($KeyA in $A.Keys) {
                if (-not ($KeysB -contains $KeyA -and $B[$KeyA] -eq $A[$KeyA]) ) {
                    return $false
                }
                $KeysB.Remove($KeyA)
            }
            if ($KeysB.Count -ne 0) {
                return $false
            }
            return $true
        }
    }

    Context "pipeline of arbitrary Object" {
        BeforeEach {
            $Objects = 1..3
            $Expected = @{ '1'=1; '2'=2; '3'=3 }
        }

        It "is invoked with no options" {
            $Actual = $Objects | ConvertTo-HashTable
            $Comparison = Compare-HashTable $Actual $Expected
            $Comparison | Should -BeTrue
        }
    }

    Context "pipeline of PSPropertyInfo" {
        BeforeAll {
            $OneTwoThree = @{ 'one'=1; 'two'=2; 'three'=3 }
        }

        BeforeEach {
            $Properties = $OneTwoThree.GetEnumerator() |
                ForEach-Object {
                    New-Object `
                        -Type 'System.Management.Automation.PSNoteProperty' `
                        -ArgumentList "$($_.Key)", $_.Value
                }
            $Expected = $OneTwoThree
        }

        It "is invoked with the FromPSPropertyInfo flag" {
            $Actual = $Properties | ConvertTo-HashTable -FromPSPropertyInfo
            $Comparison = Compare-HashTable $Actual $Expected
            $Comparison | Should -BeTrue
        }

        It "is invoked with the FromProperty flag" {
            $Actual = $Properties | ConvertTo-HashTable -FromProperty
            $Comparison = Compare-HashTable $Actual $Expected
            $Comparison | Should -BeTrue
        }
    }

    Context "pipeline of DictionaryEntry" {
        BeforeEach {
            $OneTwoThree = @{ 'one'=1; 'two'=2; 'three'=3 }
            $Entries = $OneTwoThree.GetEnumerator() |
                ForEach-Object {
                    New-Object `
                        -TypeName 'System.Collections.DictionaryEntry' `
                        -ArgumentList $_.Key, $_.Value
                }
            $Expected = $OneTwoThree
        }

        It "is invoked with the FromDictionaryEntry flag" {
            $Actual = $Entries | ConvertTo-HashTable -FromDictionaryEntry
            $Comparison = Compare-HashTable $Actual $Expected
            $Comparison | Should -BeTrue
        }

        It "is invoked with the FromEntry flag" {
            $Actual = $Entries | ConvertTo-HashTable -FromEntry
            $Comparison = Compare-HashTable $Actual $Expected
            $Comparison | Should -BeTrue
        }
    }

    Context "pipeline of custom Object" {
        BeforeAll {
            $KEY_ID = 'Letter'
            $VALUE_ID = 'Number'
            $METHOD_ID = 'Get'

            $TEST_CASES = New-Object -TypeName 'System.Collections.ArrayList'
            foreach ($ParameterSet in $PARAMETER_SETS) {
                $TestCase = $ParameterSet |
                    ForEach-Object { $_ } -PipelineVariable Name |
                    ForEach-Object `
                        -begin {
                            $VALUES = @{
                                FromPSPropertyInfo = $true
                                FromDictionaryEntry = $true
                                InputObjectIsKey = $true
                                KeyMemberName = $KEY_ID
                                KeyArgumentList = @($KEY_ID)
                                KeyScript = { $_ | ForEach-Object $KEY_ID }
                                InputObjectIsValue = $true
                                ValueMemberName = $VALUE_ID
                                ValueArgumentList = @($VALUE_ID)
                                ValueScript = { $_ | ForEach-Object $VALUE_ID }
                            }
                        } `
                        -process { $VALUES[$_] } `
                        -PipelineVariable Value |
                    ForEach-Object `
                        -begin   { $Arguments = @{ } } `
                        -process { $Arguments[$Name] = $Value } `
                        -end     {
                            if ($Arguments.ContainsKey('KeyArgumentList') ) {
                                $Arguments['KeyMemberName'] = $METHOD_ID
                            }
                            if ($Arguments.ContainsKey('ValueArgumentList') ) {
                                $Arguments['ValueMemberName'] = $METHOD_ID
                            }
                            return $Arguments
                        } |
                    Add-Member `
                        -MemberType ScriptMethod `
                        -Name 'ToString' `
                        -Value {
                            $this.GetEnumerator() |
                                ForEach-Object `
                                    -process { "$($_.Key)=$($_.Value)" } `
                                    -end { $Input -join '; ' }
                        } `
                        -Force `
                        -PassThru |
                    ForEach-Object { @{ Arguments = $_ } }

                $TEST_CASES.Add($TestCase)
            }

            $ABC = @{ 'A'=1; 'B'=2; 'C'=3 }
        }

        BeforeEach {
            $Objects = $ABC.GetEnumerator() |
                ForEach-Object {
                    New-Object `
                        -TypeName 'PSCustomObject' `
                        -Property @{
                            "$KEY_ID"   = $_.Key
                            "$VALUE_ID" = $_.Value
                        }
                } |
                Add-Member `
                    -MemberType ScriptMethod `
                    -Name $METHOD_ID `
                    -Value {
                        param($MemberName)
                        return $this | ForEach-Object -MemberName $MemberName
                    } `
                    -PassThru

            $Expected = $ABC
        }

        It "is invoked with <Arguments>" -TestCases $TEST_CASES {
            param($Arguments)

            $Actual = $Objects | ConvertTo-HashTable @Arguments
            $Comparison = Compare-HashTable $Actual $Expected
            $Comparison | Should -BeTrue
        }
    }

    # TODO test Ordered flag
}