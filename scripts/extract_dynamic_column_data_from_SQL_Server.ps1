<#
.SYNOPSIS
    .
.DESCRIPTION
    .
.PARAMETER Database
    db_name
.PARAMETER OutputDirectory
    output_directory
.PARAMETER Password
    password
.PARAMETER Query
    query => *(schema_name, table_name, column_name)  Do *not* `SET NOCOUNT OFF`.
.PARAMETER Server
    [protocol:]server[instance_name][,port]
.PARAMETER UserId
    login_id
.PARAMETER UseTrustedConnection
    (use trusted connection)
#>

# TODO: fill In script header documentation
# TODO: input validation and early exceptions
# QUESTION: do I need to account for SQL identifiers containing whitespace, any double quotes, etc.?

[CmdletBinding(PositionalBinding=$false)]
Param(

    # [protocol:]server[instance_name][,port]
    [Parameter(Mandatory=$true)]
    [Alias("S", "srv")]
    [string]
    $Server,

    # (use trusted connection)
    [Parameter(ParameterSetName="Trusted")]
    [Alias("E", "trusted")]
    [switch]
    $UseTrustedConnection,

    # login_id
    [Parameter(ParameterSetName="Untrusted")]
    [Alias("U", "uid", "UserName", "LoginId", "login", "lid")]
    [string]
    $UserId,

    # password
    [Parameter(ParameterSetName="Untrusted")]
    [Alias("P", "pwd", "pass")]
    [SecureString]
    $Password,

    # db_name
    [Parameter()]
    [Alias("d")]
    [string]
    $Database = $null,

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

    # output_directory
    [Parameter()]
    [Alias("o", "out", "output", "OutDir")]
    [string]
    $OutputDirectory = $(Get-Location)
)

####################
# CONFIGURE SCRIPT #
####################

$FNAME = '_SchemasTablesColumns';  # output file name
$EXT = 'csv';  # output file extension
$CSV = $(Join-Path -Path "$OutputDirectory" -ChildPath "$FNAME.$EXT");

#####################
# INITIALIZE SCRIPT #
#####################

# Ensure NOCOUNT And Natural Column Order
$Query = @"
SET NOCOUNT ON;

CREATE TABLE #_SchemasTablesColumns ( sch sysname, obj sysname, col sysname );

INSERT INTO #_SchemasTablesColumns ( sch, obj, col )
$Query

SELECT stc.sch, stc.obj, stc.col
FROM #_SchemasTablesColumns AS stc
    INNER JOIN sys.schemas AS sch
        ON  stc.sch = sch.name
    INNER JOIN sys.objects AS obj
        ON  stc.obj = obj.name
    INNER JOIN sys.columns AS col
        ON  stc.col = col.name
ORDER BY sch.schema_id, obj.object_id, col.column_id;
"@;  # NOTE: natural column order is necessary for this script's bcp format file definition to work properly

# Ensure Output Directory Resolves
$OutputDirectory = Resolve-Path -Path "$OutputDirectory";

# Ensure Transient File Won't Overwrite Anything
$i = 2;
While (Test-Path -Path "$CSV") {
    $CSV = $(Join-Path -Path "$OutputDirectory" -ChildPath "$FNAME_$i.$EXT");
    $i += 1;
}

###################
# VALIDATE INPUTS #
###################

# TODO: validate inputs (esp. whether the directory exists already, which it shouldn't)

################
# DO THE THING #
################

Try {

    ######################################
    # DETERMINE WHICH COLUMNS TO EXTRACT #
    ######################################

    $SEP = ',';  # field separator
    If ($UseTrustedConnection -and $Database) {
        sqlcmd -j -o "$CSV" -h -1 -s "$SEP" -W -C -u -E -S "$Server" -d "$Database" -Q "$Query";
    }
    ElseIf ($UseTrustedConnection -and -not $Database) {
        sqlcmd -j -o "$CSV" -h -1 -s "$SEP" -W -C -u -E -S "$Server" -Q "$Query";
    }
    ElseIf (-not $UseTrustedConnection -and $Database) {
        sqlcmd -j -o "$CSV" -h -1 -s "$SEP" -W -C -u -U "$UserId" -P "$Password" -S "$Server" -d "$Database" -Q "$Query";
    }
    Else {
        sqlcmd -j -o "$CSV" -h -1 -s "$SEP" -W -C -u -U "$UserId" -P "$Password" -S "$Server" -Q "$Query";
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

    ForEach ($Schema In @($SchemasTablesColumns | Group-Object -Property SchemaName) ) {

        # Create Schema Output Directory
        $SchemaDirectory = $(Join-Path -Path "$DatabaseDirectory" -ChildPath $Schema.Name);
        New-Item -ItemType 'Directory' -Path "$SchemaDirectory";

        ######################
        # PROCESS EACH TABLE #
        ######################

        ForEach ($Table In @($Schema.Group | Group-Object -Property TableName) ) {

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
            If ($UseTrustedConnection) {
                bcp "$($Schema.Name).$($Table.Name)" format nul -N -x -f "$FormatFile" -S "$Server" -d "$Database" -T;
            }
            Else {
                bcp "$($Schema.Name).$($Table.Name)" format nul -N -x -f "$FormatFile" -S "$Server" -d "$Database" -U "$UserId" -P "$Password";
            }

            # Find The SOURCE / ID For Each COLUMN / FIELD Actually Included In The Extraction Query
            [xml] $Format = $(Get-Content "$FormatFile");
            $IncludedSourceIDs = @($Format.BCPFORMAT.ROW.COLUMN |
                Where-Object Name -In $ColumnNames |
                Select-Object -ExpandProperty SOURCE
            );

            # Remove Format COLUMNs Not Included In Extraction Query
            $Format.BCPFORMAT.ROW.COLUMN |
                Where-Object SOURCE -NotIn $IncludedSourceIDs |
                ForEach-Object { $_.ParentNode.RemoveChild($_) } >$nul;

            # Remove Format FIELDs Not Included In Extraction Query
            $Format.BCPFORMAT.RECORD.FIELD |
                Where-Object ID -CNotIn $IncludedSourceIDs |
                ForEach-Object { $_.ParentNode.RemoveChild($_) } >$nul;

            $Format.Save("$FormatFile");

            #####################
            # EXTRACT DATA FILE #
            #####################

            # QUESTION: do I need to specify an error file?
            # QUESTION: should I set a maximum number of errors before aborting?  if so, how many?
            If ($UseTrustedConnection) {
                bcp "$SQL" queryout "$TableFile" -N -S "$Server" -d "$Database" -T;
            }
            Else {
                bcp "$SQL" queryout "$TableFile" -N -S "$Server" -d "$Database" -U "$UserId" -P "$Password";
            }

        }
    }
}

############
# CLEAN UP #
############

Finally {
    # TODO: remove CSV, database directory
    Remove-Item -Path "$CSV";
}
