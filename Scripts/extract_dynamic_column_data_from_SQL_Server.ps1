<#
.SYNOPSIS
    Extracts a specified set of columns from a database into ".bcp" file(s).
.DESCRIPTION
    Extracts a speciified set of columns from a database into ".bcp" file(s),
    with one file per table.  The set of columns to be extracted is determined by
    a query to be run on the specified server within the context of the specified
    database. The query should return a single result set consisting of three
    columns in the following order: "schema_name", "table_or_view_name", and
    "column_name". (the columns may be assigned different aliases, so long as the
    contents and their order is the same) The name entries should be unqualified
    and unquoted.

    The query may comprise a sequence of statements than a true
    "pure" query. However, the query should *not* execute `SET NOCOUNT OFF`; otherwise,
    undefined behavior may result.

    This script is unsigned as of 2018-07-02. As such, in order to execute, it
    should either be "unblocked" with Unblock-File or the sessions' execution
    policy should be set to "Remote Signed" with Set-ExecutionPolicy.
.PARAMETER Database
    The unqualified and unquoted name of the database from which to extract data.
.PARAMETER OutputDirectory
    The name (relative or absolute) of the directory into which to place the
    extracted data and related files.  Must already exist.  E.g. `D:\BCP`.
    Optional with default of the present working directory of the user who invokes
    this script.
.PARAMETER Password
    Is a user-specified password. Passwords are case sensitive.
.PARAMETER Query
    The (schema, table or view, column) triplets in the specified (server,
    database) from which to extract the data. The query will be executed at the
    specified server in the context of the specified database. The query must
    return exactly three columns in order of "schema_name", "table_or_view_name",
    and "column_name" where each entry be unqualified and unquoted. The columns
    may be aliased however. The default value is a selection of all columns in
    all user-defined tables.
.PARAMETER Server
    The server from which to extract the data.  An unquoted string in the format
    of "[protocol:]server[instance_name][,port]".
.PARAMETER UserId
    The login name or contained datbase user name.
.PARAMETER UseTrustedConnection
    Whehter to use a trusted connection (i.e. Microsoft Windows Authentication
    mode / "integrated login") instead of using an explicitly specified user name
    and password to log on to SQL Server.
#>

# QUESTION: do I need to account for SQL identifiers containing whitespace, any double quotes, etc.?

[CmdletBinding()]
param(

    # [protocol:]server[instance_name][,port]
    [Parameter(Mandatory=$true)]
    [Alias("S", "srv")]
    [string]
    $Server,

    # db_name
    [Parameter(Mandatory=$true)]
    [Alias("d")]
    [string]
    $Database,

    # query => *(schema_name, table_name, column_name)
    [Parameter()]
    [Alias("Q", "qry")]
    [string]
    $Query = (
        "SELECT sch.name, tbl.name, col.name " +
        "FROM sys.schemas AS sch " +
        "   INNER JOIN sys.tables AS tbl " +
        "       ON  tbl.schema_id = sch.schema_id " +
        "   INNER JOIN sys.columns AS col " +
        "       ON  col.object_id = tbl.object_id " +
        "WHERE sch.name <> 'sys' " +
        "ORDER BY sch.schema_id, tbl.object_id, col.column_id "  # MUST order by column_id witin {schema, table} for `bcp` format file to work properly
        ),

    # (use trusted connection)
    [Parameter(ParameterSetName="Trusted")]
    [Alias("E", "trusted")]
    [switch]
    $UseTrustedConnection,

    # login_id
    [Parameter(Mandatory=$true, ParameterSetName="Untrusted")]
    [Alias("U", "uid", "UserName", "LoginId", "login", "lid")]
    [string]
    $UserId,

    # password
    [Parameter(Mandatory=$true, ParameterSetName="Untrusted")]
    [Alias("P", "pwd", "pass")]
    [SecureString]
    $Password,

    # output_directory
    [Parameter()]
    [Alias("o", "out", "output", "OutDir")]
    [string]
    $OutputDirectory = $(Get-Location)
)

####################
# CONFIGURE SCRIPT #
####################

$ENDLINE = "`r`n";

$FNAME = '_SchemasTablesColumns';  # output file name
$EXT = 'csv';  # output file extension
$CSV = $(Join-Path -Path "$OutputDirectory" -ChildPath "$FNAME.$EXT");

#####################
# INITIALIZE SCRIPT #
#####################

# Ensure NOCOUNT
$Query = "SET NOCOUNT ON;$ENDLINE$Query";

# Ensure Output Directory Resolves
$OutputDirectory = Resolve-Path -Path "$OutputDirectory";

# Ensure Transient File Won't Overwrite Anything
$i = 2;
while (Test-Path -Path "$CSV") {
    $CSV = $(Join-Path -Path "$OutputDirectory" -ChildPath "$FNAME_$i.$EXT");
    $i += 1;
}

# Resolve Credentials
if (-not $UseTrustedConnection -and -not $UserId -and -not $Password) {
    $UseTrustedConnection = $true;
}

################
# DO THE THING #
################

try {

    ######################################
    # DETERMINE WHICH COLUMNS TO EXTRACT #
    ######################################

    $SEP = ',';  # field separator
    if ($UseTrustedConnection) {
        sqlcmd -j -o "$CSV" -h -1 -s "$SEP" -W -C -u -S "$Server" -d "$Database" -Q "$Query" -E;
    }
    else {
        sqlcmd -j -o "$CSV" -h -1 -s "$SEP" -W -C -u -S "$Server" -d "$Database" -Q "$Query" -U "$UserId" -P "$Password" ;
    }

    ####################
    # PROCESS DATABASE #
    ####################

    # Load Columns-To-Extract
    $SchemasTablesColumns = $(Import-CSV `
        -Path "$CSV" `
        -Delimiter "$SEP" `
        -Encoding "Unicode" `
        -Header "SchemaName", "TableName", "ColumnName"
    );

    # Create Database Output Directory
    $DatabaseDirectory = Join-Path -Path "$OutputDirectory" -ChildPath $Database;  # $Database is already a [string]
    New-Item -ItemType 'Directory' -Path "$DatabaseDirectory";

    #######################
    # PROCESS EACH SCHEMA #
    #######################

    foreach ($Schema in @($SchemasTablesColumns | Group-Object -Property SchemaName) ) {

        # Create Schema Output Directory
        $SchemaDirectory = $(Join-Path -Path "$DatabaseDirectory" -ChildPath $Schema.Name);
        New-Item -ItemType 'Directory' -Path "$SchemaDirectory";

        ######################
        # PROCESS EACH TABLE #
        ######################

        foreach ($Table in @($Schema.Group | Group-Object -Property TableName) ) {

            # Construct Table Output File Paths
            $FormatFile = $(Join-Path -Path "$SchemaDirectory" -ChildPath "$($Table.Name).xml");
            $TableFile = $(Join-Path -Path "$SchemaDirectory" -ChildPath "$($Table.Name).bcp");

            # Construct Data Query
            $ColumnNames = @($Table.Group | Select-Object -ExpandProperty ColumnName);
            $ColumnList = $($ColumnNames -join ', ');
            $SQL = $("SELECT {0} FROM {1}.{2}" -f $ColumnList, $Schema.Name, $Table.Name);

            ######################
            # DEFINE FORMAT FILE #
            ######################

            # Create Raw Format File
            if ($UseTrustedConnection) {
                bcp "$($Schema.Name).$($Table.Name)" format nul -N -x -f "$FormatFile" -S "$Server" -d "$Database" -T;
            }
            else {
                bcp "$($Schema.Name).$($Table.Name)" format nul -N -x -f "$FormatFile" -S "$Server" -d "$Database" -U "$UserId" -P "$Password";
            }

            # Find The SOURCE / ID For Each COLUMN / FIELD Actually Included in The Extraction Query
            [xml] $Format = $(Get-Content "$FormatFile");
            $IncludedSourceIDs = @($Format.BCPFORMAT.ROW.COLUMN |
                Where-Object Name -In $ColumnNames |
                Select-Object -ExpandProperty SOURCE
            );

            # Remove Format COLUMNs Not Included in Extraction Query
            $Format.BCPFORMAT.ROW.COLUMN |
                Where-Object SOURCE -NotIn $IncludedSourceIDs |
                ForEach-Object { $_.ParentNode.RemoveChild($_) } >$nul;

            # Remove Format FIELDs Not Included in Extraction Query
            $Format.BCPFORMAT.RECORD.FIELD |
                Where-Object ID -CNotIn $IncludedSourceIDs |
                ForEach-Object { $_.ParentNode.RemoveChild($_) } >$nul;

            $Format.Save("$FormatFile");

            #####################
            # EXTRACT DATA FILE #
            #####################

            # QUESTION: do I need to specify an error file?
            # QUESTION: should I set a maximum number of errors before aborting?  if so, how many?
            if ($UseTrustedConnection) {
                bcp "$SQL" queryout "$TableFile" -N -S "$Server" -d "$Database" -T;
            }
            else {
                bcp "$SQL" queryout "$TableFile" -N -S "$Server" -d "$Database" -U "$UserId" -P "$Password";
            }

        }
    }
}

############
# CLEAN UP #
############

finally {
    # TODO: remove CSV, database directory
    Remove-Item -Path "$CSV";
}
