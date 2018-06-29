# Script
A PowerShell 5 cookbook for scripting.

## Location
```powershell
# current working location of the script (determined by the caller's location)
Get-Location
```

```powershell
# location of the script file (regardless of the caller's location)
$PSScriptRoot
```