function New-List {
    <#
    .SYNOPSIS
        Creates a new list from the elements of the pipeline.
    .DESCRIPTION
        Returns a new, dynamically-sized list that is intialized with elements
        of the pipeline, if any.
    .OUTPUTS
        System.Collections.IList
            An new instance of an unspecified--but dynamically-sized--subtype of
            System.Collection.Ilist that is initialized with the elements of the
            pipeline, if any.
    #>
    end {
        $List = New-Object System.Collections.ArrayList
        foreach ($Element in $Input) {
            $List.Add($Element)
        }
        return $List
    }
}