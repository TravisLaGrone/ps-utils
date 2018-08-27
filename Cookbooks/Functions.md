# Functions
A PowerShell 5 cookbook about functions, including advanced functions.

## Splatting

### Conditional Arguments
Splats may be used to conditionally parameterize a command, similar to the
Builder pattern.

```powershell
$Splat = @{ }
$Splat['Parameter'] = $Value
if ($Condition) { $Splat['ConditionalParameter'] = $ConditionalValue }
command @Splat
```

Regarding conditional *positional* parameters, use an array-like collection (e.g.
`System.Collections.ArrayList`) instead of an array since arrays cannot be grown.
Array-like collections may be splatted as if they were arrays.

```powershell
$Splat = New-Object System.Collections.ArrayList
$Splat.Add($Argument)
if ($Condition) { $Splat.Add($ConditionalArgument) }
command @Splat
```

### External Applications
Only PowerShell functions and cmdlets accept hash table splats. However,
external applications do accept array splats.

Named arguments may be correctly converted to an array of positional arguments
appropriate for splatting to an external application by using a helper function:
```powershell
function Get-Args { $Args }
```

```powershell
C:\PS> Get-Args -Param1 'Value1' -Param2 'Value2'
-Param1
Value1
-Param2
Value2
```

This same technique also works for a hash table of named arguments:
```powershell
C:\PS> Get-Args @{ Param1='Value1'; Param2='Value2' }
-Param1
Value1
-Param2
Value2
```

Note that converting named arguments to a splattable array prepends '-' to the
name of each named argument.  If '--' is required instead, then the splattable
array should be built directly:
```powershell
C:\PS> $Splat = @( '--Param1', 'Value1', '--Param2', 'Value2' )
C:\PS> external_application @Splat
```