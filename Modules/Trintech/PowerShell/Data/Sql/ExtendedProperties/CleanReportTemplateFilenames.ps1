
dir -Path 'E:\Dropbox (Trintech)\RNET 9.3\3402-Installer\Resources\Resources\Report Templates\US' |
where name -ne 'summload.rpt' |
foreach name |
foreach {  # convert to dictionary of filename sections; one dictionary per filename
    $OrdDict = New-Object System.Collections.Specialized.OrderedDictionary

    $OrdDict.Add('category', $_.Substring(0, 1))
    $_ = $_.Substring(1)

    $OrdDict.Add('identifier', $_.Substring(0,3))
    $_ = $_.Substring(3)

    $OrdDict.Add('custom_identifier', $_.Split('#', 2)[0])
    $_ = $_.Split('#', 2)[1]

    $OrdDict.Add('description', $_.Split('#', 2)[0])
    $_ = $_.Split('#', 2)[1]

    $OrdDict.Add('type', $_.Split('.', 2)[0])
    $_ = $_.Split('.', 2)[1]

    $OrdDict.Add('extension', $_)

    return $OrdDict
} |
foreach {  # clean casing and punctuation, and tokenize
    $_['category'] = $_['category'].ToLower()

    $_['identifier'] = $_['identifier'].PadLeft(3, '0')

    $_['custom_identifier'] = $_['custom_identifier'].ToLower()

    foreach ($Key in @('description', 'type')) {
        $_[$Key] = $_[$Key].ToLower().Replace('_', ' ').Split(' ').Where({$_.Length -gt 0})
    }

    $_['extension'] = $_['extension'].ToLower()

    return $_
} |
foreach  -begin {
        $DescDict = @{
            '34'		= '34'  # COMBAK what does 34 mean?  also, see "UAR 34" below in this list
            '3bals'		= '3 Balances'  # "3" because beginning, available, and ending balances (standard set of 3?)
            '4x'		= '4x'
            '5x'		= '5x'
            'accepted'	= 'Accepted'
            'account'	= 'Account'
            'acct'		= 'Account'
            'ach'		= 'ACH'
            'activity'	= 'Activity'
            'adjusted'	= 'Adjusted'
            'audit'		= 'Audit'
            'bal'		= 'Balance'
            'balance'	= 'Balance'
            'balances'	= 'Balances'
            'bals'		= 'Balances'
            'bankfeeanalysis'	= 'Bank Fee Analysis'
            'certification'		= 'Certification'
            'contacts'	= 'Contacts'
            'csv'		= 'CSV'
            'currency'	= 'Currency'
            'date'		= 'Date'
            'deposit'	= 'Deposit'
            'depositoryactivity' = 'Depository Activity'
            'detail'	= 'Detail'
            'direct'	= 'Direct'
            'expense'	= 'Expense'
            'extended'	= 'Extended'
            'extract'	= 'Extract'
            'full'		= 'Full'
            'genledger'	= 'General Ledger'
            'insufficient'	= 'Insufficient'
            'item'		= 'Item'
            'items'		= 'Items'
            'job'		= 'Job'
            'last'		= 'Last'
            'ld'		= 'Load'
            'lddate'	= 'Load Date'
            'ledger'	= 'Ledger'
            'load'		= 'Load'
            'locks'		= 'Locks'
            'mast'		= 'Master'
            'master'	= 'Master'
            'mc'		= 'MC'  # COMBAK "master ..."?
            'minor'		= 'Minor'
            'missing'	= 'Missing'
            'multi'		= 'Multi'
            'nbrg'		= 'Never Break a Rec Group (NBRG)'
            'operator'	= 'Operator'
            'operators'	= 'Operators'
            'output'	= 'Output'
            'outstanding'	= 'Outstanding'
            'pay'		= 'Pay'
            'proof'		= 'Proof'
            'purge'		= 'Purge'
            'range'		= 'Range'
            'rec'		= 'Reconciliation'
            'reconciled'    = 'Reconciled'
            'rectype'	= ' Reconciliation Type'
            'report'	= 'Report'
            'reports'	= 'Reports'
            'reversal'	= 'Reversal'
            'select'	= 'Select'
            'serial'	= 'Serial'
            'serialactivity'	= 'Serial Activity'
            'serialbyacct'		= 'Serial by Account'
            'serials'	= 'Serials'
            'simple'	= 'Simple'
            'sr'		= 'SR'  # COMBAK "serial"?
            'stats'		= 'Statistics'
            'stop'		= 'Stop'
            'sysacct'	= 'System Account'
            'system'	= 'System'
            'trail'		= 'Trail'
            'trancode'	= 'Transaction Code'
            'type'		= 'Type'
            'uar34'		= 'UAR 34'  # COMBAK why 34? it's also at the top of this list
            'ufp'		= 'Universal File Processor (UFP)'
            'universal'	= 'Universal'
            'used'		= 'Used'
            'variance'	= 'Variance'
            'y2k'		= 'Y2K'
        }
        $TypeDict = @{
            '1tomany'	= 'One-to-Many'
            'a'		    = 'A'  # COMBAK
            'acct'	    = 'Account'
            'age'	    = 'Age'
            'all'	    = 'All'
            'ext'	    = 'Extract'
            'extract'	= 'Extract'
            'grpid'		= 'Group ID'
            'history'	= 'History'
            'l'		    = 'L'  # COMBAK
            'landscape'	= 'Landscape'
            'list'		= 'List'
            'ltd'		= 'LTD'
            'map'		= 'Map'
            'master'	= 'Master'
            'multicolumn' = 'Multicolumn'
            'portrait'	= 'Portrait'
            'range'		= 'Range'
            'simple'	= 'Simple'
            'sn'		= 'SN'  # COMBAK "serial number"?
            'st'		= 'ST'  # COMBAK "subtotal"? "system total"
            'subtotal'	= 'Subtotal'
            'subtotals'	= 'Subtotals'
            'swr'		= 'System-Wide Report (SWR)'
            'system'	= 'System'
            'trandate'	= 'Transaction Date'
            'udfx2'		= 'User-Defined Field (UDF) x2'
        }
    } -process {
        $_['description'] = @($_['description'] | ForEach-Object { $DescDict[$_] }) -join ' '
        $_['type'] = @($_['type'] | ForEach-Object { $TypeDict[$_] }) -join ' '
        return $_
    }