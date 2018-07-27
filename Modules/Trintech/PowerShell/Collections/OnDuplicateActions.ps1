enum OnDuplicateActions {
    ThrowException
    KeepFirst
    KeepLast
    KeepLesser  # if equal, then keep first
    KeepGreater  # if equal, then keep last
    Add  # binary reduction using the `+` operator
    ConstructArray
    InvokeCommand  # arbitrary user-provided script that takes two inputs and returns one
}