
#Install Azure Module
#Install-Module Az


#Download AZCopy
#Invoke-WebRequest -Uri 'https://azcopyvnext.azureedge.net/release20220315/azcopy_windows_amd64_10.14.1.zip' -OutFile 'azcopyv10.zip'
#Expand-archive -Path '.\azcopyv10.zip' -Destinationpath '.\'
#$AzCopy = (Get-ChildItem -path '.\' -Recurse -File -Filter 'azcopy.exe').FullName


$storageAccountName = "faatoppotest"
$storageAccountKey = "BjO/4t+2DJkr54eWHDvxC+BhcvgOtgR/Gc1syr67IbMiZHTCB9Jy9aj5DYfo1ZjEM1OmS5WoEUvZ+AStMcdIuQ==" 

#SASToken StartTime & EndTime
$StartTime = Get-Date
$EndTime = $startTime.AddHours(8)

#AzCopy
$destinationLocation = "C:\Tmp"
$IPAddressOrRange = "8.8.8.8-8.8.8.10"



###################################Run-script###################################

# Get StoageContext

$storageContext =  New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Generate SAS URI

Get-AzStorageContainer -Context $storageContext

$SASToken = New-AzStorageAccountSASToken -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission "rl" -ExpiryTime (Get-Date).AddDays(1) -Context $storageContext  #-IPAddressOrRange $IPAddressOrRange

$SASURI = "https://"+ $storageAccountName + ".blob.core.windows.net/"+$SASToken


#Table

$tables = Get-AzStorageTable -Context $storageContext
$tables | Sort-Object -Property "CloudTable" | Select-Object CloudTable,Uri | Export-Csv "$destinationLocation\tables.csv" -Encoding UTF8
 
$backupTable = import-csv "$backupDir\tables.csv" -Encoding UTF8



foreach($t in $backupTable) {
        $tableUrl = $t.Uri
        $tableName = $t.CloudTable
        Write-Host ("`nBacking up table $tableName") -ForegroundColor Yellow
        .\AzCopy.exe $tableUrl+$SASToken $destinationLocation  /Manifest:"$tableName.manifest"
    }
#AzCopy

#.\azcopy.exe copy $SASURI $destinationLocation  --recursive=true


#https://www.rlvision.com/blog/how-to-backup-and-restore-tables-in-azure-storage/