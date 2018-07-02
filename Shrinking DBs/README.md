# Shrinking Databases

So, a lot has been said about shrinking databases. There are plenty of reasons not to do it, but there are times you have to. These scripts have come in handy for me when I've needed to shrink a lot of databases.

# Shrink_Logs.ps1

This script is really, really basic. It just grabs a list of all databases on a specific server and shrinks them.

# Shrink_Logs_ByAG.ps1

This is a bit more involved. We needed to shrink a bunch of databases that were bloated by errant tables (data was never purged) in a specific Availability Group. This script grabs a list of databases in the AG and shrinks them, but we calculate the value to shrink the DB to based on the current space used. We get the current spaced used, and add 256MB to it to be the new size that we want - the 256MB comes from a standard autogrowth rate across of these DBs. The script also outputs the before/after sizes to a log file that you give it. It's ugly but it got the job done. 

