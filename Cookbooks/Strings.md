# Strings
A PowerShell 6 cookbook about strings and string manipulation.

## Regex

```powershell
# Remove the " - Shortcut" from the name of all shortcuts in the current directory.
dir |
    where name -like '* - Shortcut.lnk' |
    % { mv $_ ([regex]::Match($_, '(.*) - Shortcut').captures.groups[1].value + '.lnk') }
```

```powershell
# Extract all Conda environment specification files ("spec list") names less the path and extension.
conda list --explicit |
    sls -Pattern '^https' |
    % { [regex]::Match($_, '/([^/]+?)\.tar.bz2').captures.groups[1].value }
```

```powershell
# Change all a certain extension of all files in a folder to another extension.
dir -File |
    where name -like '%.{ext1}' |
    % { mv $_ "$([regex]::Match($_, '(.*)\.{ext1}').captures.groups[1].value).{ext2}" }
```

```powershell
# Join a pipeline of strings into one string.
$sb = [System.Text.StringBuilder]::new()
strings | % { [void]$sb.Append($_) }
```