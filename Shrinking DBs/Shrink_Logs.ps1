Import-Module sqlps -DisableNameChecking

$dbs = Invoke-SqlCmd -ServerInstance 'servername' -Query "select name from sys.databases where database_id > 4"

foreach($db in $dbs){
	$Log = Invoke-Sqlcmd -ServerInstance 'servername' -Database $db.name -Query "select name from sys.master_files where database_id = db_id() and type = 1"
	$LogName = $Log.name
	$query = "DBCC SHRINKFile($LogName, 1)"
	Invoke-Sqlcmd -ServerInstance 'servername' -Database $db.name -Query $query
}