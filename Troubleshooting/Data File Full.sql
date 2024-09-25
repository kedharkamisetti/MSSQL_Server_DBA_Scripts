--1) Find the space utilization
sp_spaceused
sp_helpdb

--2) Find the drive space availability
xp_fixeddrives

--3) Perform cleanup operations using different techniques like deleting backups in other drives, shrinking the large log files, shrinking data files if possible. Doing all this will create space and we can temporarily use that space till Windows Team arranges for the space expansion of the drive. For identifying which folders to cleanup we can use Tree Size software.

--4) Add a new data file to the database.If no space then request your Windows team to add more space (or) perform cleanup operations. 

--5) Shrink the data file and don't forget to rebuild indexes after shrink operation (as it causes fragmentation).