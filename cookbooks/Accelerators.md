# Accelerators
A PowerShell 5 cookbook about type accelerators.  Type accelerators are an
undocumented feature defined in `System.Management.Automation.TypeAccelerators`.

## Access

`TypeAccelerators` object:
```powershell
$TAType = [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators");
```

Accelerated `TypeAccelerators` object:
```powershell
$TAType = [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators");
$TAType::Add('accelerators', $TAType);
```

All accelerators in current session:
```powershell
$TAType = [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators");
$TAType::Add('accelerators', $TAType);
[accelerators]::Get;
```