# XML
A PowerShell 5 cookbook for XML.

## Text

From file:
```powershell
$XmlDocument = [xml] $(Get-Content -Path 'file-location' );
```

## CLI XML


## Linq

From string:
```powershell
$XDocument = [System.Xml.LINQ.XDocument]::Parse( $( $(Get-Content -Path 'file-location') -join '') );
```

Format:
```powershell
$XDocument.ToString();
```