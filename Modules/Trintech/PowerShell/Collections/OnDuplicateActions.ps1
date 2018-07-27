enum OnDuplicateActions {
    ThrowException
    KeepFirst
    KeepLast
    KeepLesser  # if equal, then keep first
    KeepGreater  # if equal, then keep first
    Add  # invoke the `+` operator
    ConstructArray
    InvokeCommand
}