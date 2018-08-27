# Commands
A PowerShell 5 cookbook about commands.

## To CSV
```powershell
Get-Command -CommandType cmdlet |
    ForEach { New-Object PSObject -Property @{
        Module=$_.ModuleName;
        Type=$_.CommandType;
        Command=$_.Name;
        Verb=$_.Verb;
        Noun=$_.Noun;
        Synopsis=$(Get-Help $_).Synopsis}
    } |
    Export-CSV -path 'cmdlets.csv'
```