#PS Script to get Cluster Configuration Report

<#
https://yogeshsql.wordpress.com/2016/04/22/powershell-script-to-get-cluster-configuration-report/
Written by : Yogesh
Date : 22-Apr-2016
Script created to keep cluster configuration information in a text file for emergency purpose.
#>

#Cluster information will be generated on date and time. Every day new file will be created.

Import-Module FailoverClusters
# Change the desired file location for evey server

$OutputFileLocation = “C:\ClusterInfoLogs-$(get-date -uformat ‘%Y-%m-%d-%H_%M’).log”
# Heading comment

write-output “******Cluster IP-Address*****” | Out-File $OutputFileLocation -Append
write-output “—————————–” | Out-File $OutputFileLocation -Append

$ClusterName=Get-Cluster;
$ClusterName.name | Out-File $OutputFileLocation -Append
$ipV4 = Test-Connection -ComputerName $ClusterName -Count 1 | Select IPV4Address
$ipV4 | Out-File $OutputFileLocation -Append

#———————————————————————
Write-Output “****** Cluster Node*****” | Out-File $OutputFileLocation -Append
Get-ClusterNode | Out-File $OutputFileLocation -Append

#———————————————————————-
Write-Output ” ClusterNodes IP address ” | Out-File $OutputFileLocation -Append
$ClusterNodes=Get-ClusterNode

ForEach($item in $ClusterNodes)
{
write-output “********************************************* $item **************************************************” | Out-File $OutputFileLocation -Append

$ipV4 = Test-Connection -ComputerName $item.name -Count 1 | Select IPV4Address
$ipV4 | Out-File $OutputFileLocation -Append

}

#———————————————————————-
write-output ” ——–Resources Dependency ———————” | Out-File $OutputFileLocation -Append

$clusterNodes = Get-ClusterGroup | Where {$_.Name -like “S*”};
ForEach($item in $clusterNodes)
{
write-output “********************************************* $item *************************************************” | Out-File $OutputFileLocation -Append

Get-ClusterGroup $item.Name | Get-ClusterResource | Get-ClusterResourceDependency | Out-File $OutputFileLocation -Append -Width 400

}
#———————————————————————–
# Existing resource group list
write-output “******Cluster group******” | Out-File $OutputFileLocation -Append
Get-ClusterGroup | Out-File $OutputFileLocation -Append

#———————————————————————–
#Ip-Address of SQL servr
#Note- Need to change the server name for each cluster
write-output “****** Cluster IP addresses ******” | Out-File $OutputFileLocation -Append
$ClusterResource=Get-ClusterResource -Cluster $ClusterName | Where-Object {$_.Name -like “SQL IP*”} | Sort-Object -Property OwnerGroup
ForEach($item in $ClusterResource)
{
write-output “********************************************* IP-Address of $item *************************************************” | Out-File $OutputFileLocation -Append

Get-ClusterResource $item.name | Get-ClusterParameter | Out-File $OutputFileLocation -Append -width 200

}
#————————————————————————–
#Cluster disk information
write-output “*****List of Cluster disk with Group*****” | Out-File $OutputFileLocation -App
$clusterNodes = Get-ClusterGroup | Where {$_.Name -like “S*”};
ForEach($item in $ClusterNodes)
{
write-output “********************************************* Disk of $item *************************************************” | Out-File $OutputFileLocation -App
Get-ClusterGroup | Get-ClusterResource | Where {$_.ResourceType.Name -eq “Physical Disk” -and $_.OwnerGroup.name -eq $item.name } | Out-File $OutputFileLocation -Append
}