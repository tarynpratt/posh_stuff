<#
.SYNOPSIS
    Shrink log files within a specific AG
#>

[CmdletBinding()] #See http://technet.microsoft.com/en-us/library/hh847884(v=wps.620).aspx for CmdletBinding common parameters
param(
    [parameter(Mandatory = $true)]
    [string]$ServerName,
    [parameter(Mandatory = $true)]
    [string]$AG_Name,
    [parameter(Mandatory = $true)]
    [string]$OutputFile
)

Import-Module sqlps -DisableNameChecking

$dbs = Invoke-SqlCmd -ServerInstance $ServerName -Query "SELECT 
                                                            db_name = d.name,
                                                            d.database_id,
                                                            filename = f.name,
                                                            f.type
                                                        FROM sys.databases d
                                                        INNER JOIN sys.master_files f
	                                                        ON d.database_id = f.database_id
                                                        WHERE d.database_id > 4
                                                            AND f.type = 0
                                                            AND EXISTS (SELECT 1
				                                                        FROM sys.dm_hadr_database_replica_states drs
				                                                        INNER JOIN sys.availability_groups ag
					                                                        ON drs.group_id = ag.group_id
				                                                        WHERE d.database_id = drs.database_id
                                                                            AND ag.name = '$AG_Name')
                                                        ORDER BY f.size, d.name"

# Add total count to the file
'Total database in the '+$AG_Name+' AG to be shrunk: '+$dbs.db_name.count | Out-File -FilePath $OutputFile -Append

$n = 1
foreach($db in $dbs){
    $db_name = $db.db_name
    $file_name = $db.filename
    
    # annotate the output file with the database selected
    'DB #'+$n+' - prepping to shrink database '+ $db_name +' and file: '+ $file_name | Out-File -FilePath $OutputFile -Append 

    # get the space used for each file
    # this will be used to determine what to shrink to
    $space_query = "USE [$db_name]; 
                    SELECT filesize = CAST(size/128.0 AS DECIMAL(10,2)), spaceused = CAST(FILEPROPERTY(name, 'SpaceUsed')/128.0 AS DECIMAL(10,0)) 
                    FROM sysfiles WHERE name = '$file_name'"

    $before_shrink = Invoke-Sqlcmd -ServerInstance $ServerName -Database $db_name -Query $space_query

    # the new size is the spaceused value plus the autogrowth rate for our DBs
    $new_size = $before_shrink.spaceused + 256

    # add details about the size of the database before shrinking
    'Before shrinking the database size was: ' + $before_shrink.filesize + ' and space used was: '+ $before_shrink.spaceused +'. The new size should be '+$new_size | Out-File -FilePath $OutputFile -Append 

    $shrink_query = "USE [$db_name]; DBCC SHRINKFILE(N'$file_name', $new_size)"

    'The shrink command for this database is: '+$shrink_query | Out-File -FilePath $OutputFile -Append 

    # execute the SHRINKFILE command for each database
    Invoke-Sqlcmd -ServerInstance $ServerName -Database $db_name -Query $shrink_query | Out-File -FilePath $OutputFile -Append 

    # query that the shrink took 
    $after_shrink = Invoke-Sqlcmd -ServerInstance $ServerName -Database $db_name -Query $space_query 

    # add details about the size of the database after shrinking
    'After shrinking the database size is: ' +$after_shrink.filesize +' and space used is: '+ $after_shrink.spaceused +'.' | Out-File -FilePath $OutputFile -Append 

    # add line break
    Add-Content -Path $OutputFile -Value "`r`n"

    $n = $n + 1
}

