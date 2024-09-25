--to see the list of endpoints
select * from sys.endpoints

--to create an endpoint
create endpoint endpointname
state = started
as tcp
(listener_port = portnumber, listener_ip = all)
for tsql();

--to grant connect to a specific login
grant connect on endpoint :: endpointname to loginname

--to grant connect to everyone
grant connect on endpoint :: [tsql default tcp] to [public]

--to revoke connect 
revoke connect on endpoint :: endpointname to loginname

--to change the status of endpoint
alter endpoint endpointname state = stopped

--to drop an endpoint
drop endpoint endpointname