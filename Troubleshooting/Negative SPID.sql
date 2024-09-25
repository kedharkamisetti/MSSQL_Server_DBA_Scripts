--it can be -2 or -3 or -4.
--if it is "-2", we can solve it.
--if it is "-3" or "-4", we have to raise a ticket to microsoft to solve it.

--to solve "-2", first run the following command:
select req_transactionUOW from master..syslockinfo where req_spid = -2
--the above command will give you UOW (unit of work) in result
--then copy the uow value and then kill it
kill 'UOW'
--ex: kill '1l32i5ypj452lk4u5po4i5g43y3f'

--we can also find this UOW in Start > Run > dcomcnfg