select @@servername, GL.dns_name as AG_ListenerName,GL.port as PortNo, 
GL.ip_configuration_string_from_cluster as AG_IP_Addresses
from sys.availability_group_listeners GL