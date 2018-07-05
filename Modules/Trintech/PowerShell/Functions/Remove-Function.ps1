function Remove-Function
{
    <#
    .SYNOPSIS
        Removes an item by name from the 'Function:' PSDrive.
    .PARAMETER FunctionName
        The name of the function to remove. If not provided, then all items in
        the 'Function:' PSDrive are removed.
    #>
    [CmdletBinding()]
    Param
    (
        # The name of the function to remove, or all functions if null
        [Parameter(ValueFromPipeline=$true,
                   ParameterSetName='name')]
        [ValidateScript({Test-Path "Function:$_"})]
        [ValidateScript({$(Get-Item "Function:$_").GetType().Name -eq 'FunctionInfo'})]
        [string]
        $FunctionName,

        # The [System.Management.Automation.FunctionInfo] corresponding to the function to remove.
        [Parameter(Mandatory=$true,
                   ParameterSetName='info')]
        [System.Management.Automation.FunctionInfo]
        $FunctionInfo
    )
    Process
    {
        Remove-Item "Function:$FunctionName";
    }
}

New-Alias -Name 'rmfn' -Value 'Remove-Function';