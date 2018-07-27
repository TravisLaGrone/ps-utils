function New-List {
    $List = New-Object 'System.Collections.ArrayList'
    foreach($Element in $Input) {
        $List.Add($Element)
    }
    return $List
}