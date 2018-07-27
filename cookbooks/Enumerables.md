# Enumerables
A PowerShell 5 cookbook about the .NET
[System.Collections.IEnumerable](https://docs.microsoft.com/en-us/dotnet/api/system.collections.ienumerable).

## Vectorized Operations

**Flatten**
```powershell
filter Flatten {
    foreach($element in $_) {
        $element
    }
}
```
