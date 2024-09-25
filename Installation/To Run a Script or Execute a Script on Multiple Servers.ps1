# Script Runs on servers listed in serverlist.txt
# use sqlps.exe to run this script
# In cmd, sqlps.exe c:\scripts\script.ps1
 
$query = "select @@VERSION"
 
#Path to the excel file to be saved.
 
$csvFilePath = "c:\testing\queryresults.csv"
$excelFilePath = "c:\testing\queryresults.xls"
 
# Run Query against multiple servers, combine results
# Replace "Server1", "Server2\INSTANCE1" with names of your SQL Server instances
 
$instanceNameList = get-content C:\serverlist.txt
 $results=@()
  
foreach($instanceName in $instanceNameList)
{
        write-host "Executing query against server: " $instanceName
        $results += Invoke-Sqlcmd -Query $query -ServerInstance $instanceName
}
 
# Output to CSV
 
write-host "Saving Query Results in CSV format..."
$results | export-csv  $csvFilePath   -NoTypeInformation
# Convert CSV file to Excel
# Reference : <a href="http://gallery.technet.microsoft.com/scriptcenter/da4c725e-3487-42ff-862f-c022cf09c8fa">http://gallery.technet.microsoft.com/scriptcenter/da4c725e-3487-42ff-862f-c022cf09c8fa</a>
 
write-host "Converting CSV output to Excel..."
 
$excel = New-Object -ComObject excel.application
$excel.visible = $False
$excel.displayalerts=$False
$workbook = $excel.Workbooks.Open($csvFilePath)
$workSheet = $workbook.worksheets.Item(1)
$resize = $workSheet.UsedRange
$resize.EntireColumn.AutoFit() | Out-Null
$xlExcel8 = 56
$workbook.SaveAs($excelFilePath,$xlExcel8)
$workbook.Close()
$excel.quit()
$excel = $null
 
write-host "Results are saved in Excel file: " $excelFilePath