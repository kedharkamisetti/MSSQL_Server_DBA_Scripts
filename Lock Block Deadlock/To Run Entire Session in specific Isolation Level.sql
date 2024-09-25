--add this line in the beginning of the all the commands
set transaction isolation level isolationlevelname
--ex: set transaction isolation level read committed
--Isolation levels:
							--pesimistic:
									--read committed
									--read uncommitted
									--repeatable read
									--serializable
							--optimistic:
									--snapshot
										--snapshot read committed

--to use snapshot isolation level, first turn on setting called "allow snapshot isolation" @ db level settings and also add the command in the query window.
--to use snapshot read committed, turn on setting called "is read committed snapshot on" @ db level.