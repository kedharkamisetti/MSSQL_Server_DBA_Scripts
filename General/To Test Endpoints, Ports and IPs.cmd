:: run these in CMD

:: to check the ping between machines using IP
ping ipaddress
:: ex: ping 10.0.0.143

:: to check the ping between machines using machine name
ping machinename

:: to check a port is open or not
:: we need to have telnet feature installed in the server to run this in CMD
telnet ipaddress portnumber
:: or
telnet machinename portnumber
:: ex:telnet 10.0.0.143 5022
:: if it is open, it is show a cursor in CMD

:: to check a port is listening or not
netstat -abn | findstr portnumber