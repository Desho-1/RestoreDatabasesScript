# RestoreDatabasesScript


the purpose of this script is to restore multiple databases in 1 step, this generates TSQL command for each backup file with reallocate (data,log) option

sqlserver script that restore all databases specified in the directory

input: database backup location (path)

option: restore databases with reallocate option

output: restore scripts for each database ready to be excuted 
