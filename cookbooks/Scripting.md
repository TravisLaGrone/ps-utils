# Script
A PowerShell 5 cookbook for scripting.

## Location

### Caller-Independent

Directory location of the script file (regardless of the caller's location):
```powershell
$PSScriptRoot  # type: [string]
```

File location of the script file (regardless of the caller's location):
```powershell
$PSCommandPath  # type: [string]
```

### Caller-Dependent

Current working location of the script (determined by the caller's location):
```powershell
Get-Location  # type: [System.Management.Automation.PathInfo]
```