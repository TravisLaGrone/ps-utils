$ErrorActionPreference = 'Stop'

function Add-SourceFile([String[]]$Path) {

    $CompilationUnit = New-Object System.Text.StringBuilder

    $AddTypeArgs = @{}

    if ($PSVersionTable.PSVersion.Major -ge 3) {
        $AddTypeArgs.Language = 'CSharp'
        $AddTypeArgs.ReferencedAssemblies = @('System.Core', 'System.Data', 'System.Xml')
    }
    else {
        $AddTypeArgs.Language = 'CSharpVersion3'
        $AddTypeArgs.ReferencedAssemblies = @('System.Data', 'System.Xml')
    }

    foreach ($SourcePath in $Path) {

        if ($SourcePath -notlike '*.cs') { throw 'Add-SourceFile only supports the C# language.' }

        [Void]$CompilationUnit.AppendLine([IO.File]::ReadAllText("$PSScriptRoot\$SourcePath"))
        [Void]$CompilationUnit.AppendLine()

    }

    $AddTypeArgs.TypeDefinition = $CompilationUnit.ToString()

    Add-Type @AddTypeArgs

}

Add-SourceFile @(
    'PSComparer.cs'
    'PSEnumerable.cs'
    'PSEnumerator.cs'
    'PSEqualityComparer.cs'
    'PSFunc.cs'
    'PSReverseComparer.cs'
)