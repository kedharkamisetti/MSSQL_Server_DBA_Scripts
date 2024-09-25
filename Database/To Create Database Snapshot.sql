create database databasesnapshotname
on ( name = logicalfilenameofsourcedatabasemdffile, 
filename = 'path(snapshotpath)\filename(snapshotphysicalfilename).ss')
as snapshot of sourcedatabasename;
go