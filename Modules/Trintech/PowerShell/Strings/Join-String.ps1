function Join-String
{
    <#
    .SYNOPSIS
        Joins a pipline of string(s).
    .PARAMETER Delimter
        The (optional) separator with which to delimit the joined strings.
    .PARAMETER Prefix
        The (optional) prefix to prepend to the resulting joined string.
    .PARAMETER Suffix
        The (optional) suffix to append to the resulting joined string
    .PARAMETER DefaultString
        The (optional) string to return instead if the resulting joined string
        (before joining the prefix and/or suffix) is empty. The DefaultString is
        returned *without* prepending/appending the prefix/suffix. If the value
        of DefaultString is $null and the delimited concatenation of all
        InputString's is empty (i.e. -eq ''), then the concatenation of the
        Prefix and Suffix is returned.
    .PARAMETER SkipNull
        Whether to skip null input values.
    .PARAMETER SkipEmpty
        Whether to skip input values whose string representation is empty (e.g. "$null" => '').
    .INPUTS
        Object
            The object(s) to join together as strings.
    .OUTPUTS
        System.String
            The input(s) joined as a string.
    .NOTES
        Treats null values as emtpy strings.
    .EXAMPLE
        'A', 'B', 'C' | Join-String
        ABC
    .EXAMPLE
        'A', 'B', 'C' | Join-String -Delimiter ', ' -Prefix '(' -Suffix ')'
        (A, B, C)
    .EXAMPLE
        @( ) | Join-String -Delimiter ', ' -Prefix '(' -Suffix ')'
        ()
    .EXAMPLE
        '', '', '' | Join-String -Prefix '(' -Suffix ')' -DefaultString 'NULL'
        NULL
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        # The string with which to delimit the joined strings
        [Parameter()]
        [ValidateNotNull()]
        [Alias('Separator')]
        [String]
        $Delimiter = '',

        # The string to prepend to the resulting joined string
        [Parameter()]
        [ValidateNotNull()]
        [Alias('Prepend')]
        [String]
        $Prefix = '',

        # The string to append to the resulting joined string
        [Parameter()]
        [ValidateNotNull()]
        [Alias('Append')]
        [String]
        $Suffix = '',

        # The string to return if the resulting joined string is empty (before joining the prefix and/or suffix)
        [Parameter()]
        [Alias('Default')]
        [String]
        $DefaultString = $null,

        # Whether to skip null input values
        [Parameter()]
        [Switch]
        $SkipNull,

        # Whether to skip input values whose string representation is empty (e.g. '').
        [Parameter()]
        [Switch]
        $SkipEmpty,

        # The pipeline of object(s) to join together as strings.
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [AllowEmptyString()]
        [AllowNull()]
        $InputObject
    )
    $Strings = $Input;

    #region PreProcess
    if ($SkipNull)  { $Strings = $Strings | Where-Object { $_ -ne $null }; }
    $Strings = $Strings | ForEach-Object { "$_" };  # treats nulls as empty strings
    if ($SkipEmpty) { $Strings = $Strings | Where-Object { $_ -ne '' }; }
    #endregion PreProcess

    #region Join
    $Joined = $Strings -join $Delimiter;
    if (-not $Joined -and $DefaultString -ne $null) {
        return $DefaultString;
    }
    return -join @($Prefix, $Joined, $Suffix);  # requires parentheses since the join operator has higher precedence than a comma
    #endregion Join
}