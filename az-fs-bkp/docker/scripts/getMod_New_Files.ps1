
Import-Module PowerShellGet
Install-Module -Name Az.Accounts -Force -Verbose
Install-Module -Name Az.Compute -Force -Verbose
Install-Module -Name Az.Resources -Force -Verbose
Install-Module -Name Az.Storage -Force -Verbose
Import-Module Az.Accounts
Import-Module Az.Compute
Import-Module Az.Storage
Import-Module Az.Resources
$error | out-file /scripts/logs.txt -append

$nodenumbervar = (get-ChildItem Env:nodenumber).value
#determine which line of the CSV file to process.
$split = "$nodenumbervar" -split "cronjob-node"
$nodenumber = $split[1]
$csv = import-csv /scripts/inputCSV.csv
$rowtoProcess = $csv[$nodenumber]

$subscriptionName = $rowtoProcess.subscriptionName
$storageAccountRG = $rowtoProcess.storageAccountRG
$storageAccountName = $rowtoProcess.storageAccountName
$tenantId =  $rowtoProcess.tenantID
$FileShares = $rowtoProcess.FileShares
$storageAccountRGDest = $rowtoProcess.storageAccountRGDest
$storageAccountNameDest = $rowtoProcess.storageAccountNameDest
$destContainer = $rowtoProcess.destContainer

#$EmailUserName = Get-Content "/etc/emailcredentials/emailusername"
#$EmailPassword = Get-Content "/etc/emailcredentials/emailpassword"
$servicePrincipalClientId = get-content /etc/dacreds/servicePrincipalClientId
$servicePrincipalClientSecret = get-content /etc/dacreds/servicePrincipalClientSecret
#################################
$clientID = "$servicePrincipalClientId"
$passwd = "$servicePrincipalClientSecret"
$secpasswd = ConvertTo-SecureString  -AsPlainText -Force -string $passwd
$pscredential = New-Object System.Management.Automation.PSCredential($clientID, $secpasswd)
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId #|Out-Null
###########################################
#$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$vstspat)))


# Select right Azure Subscription
Select-AzSubscription -SubscriptionName $subscriptionName |Out-Null
Set-AzCurrentStorageAccount -ResourceGroupName $storageAccountRG -StorageAccountName $storageAccountName | Out-Null #to suppress output.

if($FileShares -eq "*"){$allShares = (Get-AzStorageshare |Select Name).Name}
else{$allShares = $FileShares -split ","}

[int]$batchSize = 1000 ###should be 1000 for storage account of type standard, if premium can handle more, increase it.
[datetime]$timecus = (Get-Date).addhours(-24).ToUniversalTime()

[array]$JobDetails=@()
$JobOutputModified = @()
$JobOutputCreated = @()

Function GetSubFolders($item)
{
    
    $CurrSubFoldersList = @()
    $CurrSubFoldersListActual =@()
    $CurrSubFoldersList = (Get-AzStorageFile -ShareName $fileShareName -Path $item | Get-AzStorageFile| where {$_.GetType().Name -eq "CloudFileDirectory"} | Select Name,Parent,URI).uri.AbsolutePath
    Foreach($folder in $CurrSubFoldersList)
    {
        $folderCorrectPath = $folder -replace "/$fileShareName/"
        $CurrSubFoldersListActual += $folderCorrectPath
    }
    
    if($($CurrSubFoldersListActual|Measure).Count -gt 0)
    {
         $AllSubFoldersList += $CurrSubFoldersListActual
         Foreach($item in $CurrSubFoldersListActual)
         {
    
            GetSubFolders $item
         }
    }
    
    Return $AllSubFoldersList
}

Foreach($fileShareName in $allShares)
{
    $rootFolders = (Get-AzStorageFile -ShareName $fileShareName | where {$_.GetType().Name -eq "CloudFileDirectory"}).Name
    $JobOutputModified = @()
    $JobOutputCreated = @()

    Foreach($folder in $rootFolders)
    {
    $AllSubFoldersList = GetSubFolders $folder
    
    }
    $AllSubFoldersList+=$rootFolders

    $AllSubFoldersList = $AllSubFoldersList | Select -Unique

    Foreach($folderPath in $AllSubFoldersList)
    {
    write-host "processing folder $folderpath --------- share $fileShareName"
    $error.clear()
    $files = Get-AzStorageFile -ShareName $fileShareName -path "$folderPath" | Get-AzStorageFile | where {$_.GetType().Name -ne "CloudFileDirectory"}
    $random = get-random -Maximum 5 #if multiple jobs try to connect at the same time, Az throws an error so we are adding random delay.
    $retries=0 #if the storage account is too busy it throttles the connections
    if($error.Count -gt 0)
    {
        do
        {
            start-sleep -s $random
            $error.clear()
            $files = Get-AzStorageFile -ShareName $fileShareName -path "$folderPath" | Get-AzStorageFile | where {$_.GetType().Name -ne "CloudFileDirectory"}
            $retries += 1
        }while($error.Count -gt 0 -and $retries -lt 3)
    }
    

    [int]$count = ($files | Measure).Count

    if($batchSize -ge $count -and $count -ne 0)
    {
        $numberofBatches = 1
        $lastBatchCount =  $count
    }
    Elseif($batchSize -lt $count -and $count -ne 0)
    {
        $numberofBatches = [math]::round($count/$batchSize)
        $lastBatchCount =  -(([math]::round($count/$batchSize))*$batchSize-$count) 
    }
    elseif($count -eq 0)
    {
        $numberofBatches = 0
        $lastBatchCount =  0
    }
      #$numberofBatches = 1 #use only for testing with smaller batch -- the script itself..
    #####
                                                                                                                                                                                                            $Functions = {
param([int]$i, [int]$batchSize, [string]$fileShareName, $timecus,  $folderPath, $storageAccountRG, $storageAccountName)
$OutputArray = @(@(),@()) # 2 dimensional

Function FindFiles($i, $batchsize, $fileShareName, $timecus, $folderPath, $storageAccountRG, $storageAccountName, $filesExistonShareroot)
 {
    $modifiedFilesList = @()
    $createdFilesList = @()
    $retries=0
    #if multiple jobs try to connect at the same time, Az throws an error so we are adding random delay.
    do
    {
        $random = get-random -Maximum 5 
        start-sleep -s $random
        $error.clear()
        Set-AzCurrentStorageAccount -ResourceGroupName $storageAccountRG -StorageAccountName $storageAccountName | Out-Null
        $retries += 1
    }while($error.Count -gt 0 -and $retries -lt 3)
        
        $files = Get-AzStorageFile -ShareName $fileShareName -path "$folderPath" | Get-AzStorageFile
    
    [int]$startingFileNumber = $i * $batchSize
    if($i -eq $count-1)
    {
        [int]$endingFileNumber = $lastBatchCount - 1 #array from 0
    }
    else
    {
        [int]$endingFileNumber = $startingFileNumber + ($batchSize - 1)
    }
    
    for($j=$startingFileNumber;$j -le $endingFileNumber;$j++)
    {   
        $files[$j].fetchattributes()

         #$filenameshort = $files[$j].name  -- this is slow and also adds  GetDirectoryProperties API count by 100%. 
         #$Details = Get-AzStorageFile -Path "temp/$filenameshort" -ShareName $fileShareName
        #new folders created are also captured in the createfileslist array, we need to filter this out -- done in the later for loops
        
        if($files[$j].properties.creationtime.UTCDateTime -gt $timecus)
        {
           [string]$fullpath = $folderPath+ "/" + $files[$j].Name  
          # Write-Output $fullpath    
           $createdFilesList += $fullpath                 
        }
        elseif($files[$j].Properties.lastmodified.utcdatetime -gt $timecus)
        {
           [string]$fullpath = $folderPath+ "/" + $files[$j].Name  
          # Write-Output $fullpath    
           $modifiedFilesList += $fullpath                 
        }
    }
    Return $modifiedFilesList, $createdFilesList
    
 }
 FindFiles $i $batchsize $fileShareName $timecus  $folderPath $storageAccountRG $storageAccountName $filesExistonShareroot
 $OutputArray = $modifiedFilesList, $createdFilesList
 Write-Output $OutputArray
    }
 for($i=0;$i -lt $numberofBatches;$i=$i+1)
 {
    do
    {
        $numofJobsRunning = (get-job | where {$_.State -eq "running"} |Measure).Count 
        start-sleep -Milliseconds 250
    }while($numofJobsRunning -gt "10")
    $JobDetailsTemp = @()
    $JobDetailsTemp = Start-Job  -ScriptBlock $Functions -ArgumentList ($i,$batchSize,$fileShareName,$timecus,$folderPath, $storageAccountRG, $storageAccountName)
    $JobDetails += $JobDetailsTemp
    } 

 }

 #wait for all the jobs in the current share is over before moving on to the next share
    Do{
        start-sleep -Seconds 1
        $timeWaited+=1     
       }while((Get-Job | where {$_.State -eq "Running"} |Measure).Count -gt 0 -and $timeWaited -lt "7200")


    Foreach($JobDetail in $JobDetails)
    {
        $JobOutputModifiedtemp = @()
        $JobOutputCreatedTemp = @()

        $JobOutputModifiedtemp = ((Get-Job -Id $JobDetail.id |Select ChildJobs).Childjobs|Select Output).Output[0]
        $JobOutputCreatedtemp = ((Get-Job -Id $JobDetail.id |Select ChildJobs).Childjobs|Select Output).Output[1]
        $JobOutputModified+=$JobOutputModifiedtemp
        $JobOutputCreated+=$JobOutputCreatedtemp
    }
    write-output "output modified list for $filesharename is now" $JobOutputModified
    write-output "output created list for $filesharename is now" $JobOutputCreated
    $JobDetails = @()

    $dateFolder = get-date -Format yyyyMMdd
    New-Item -ItemType Directory $dateFolder/$filesharename/Modified -Force
    New-Item -ItemType Directory $dateFolder/$filesharename/Created -Force
    #Download the files and copy them locally with the same folder structure. This whole bundle can then be uploaded to BLOB as is.
    Foreach($file in $JobOutputModified)
    {
            #to filter the folders that somehow come in this list generated.
            if(Get-AzStorageFile -ShareName $fileShareName -path $file |where {$_.GetType().Name -ne "CloudFileDirectory"})
            {
                [string]$LocalFolderPath =""
                Get-AzStorageFileContent -Path $file -ShareName $fileShareName -Force
                $FolderNamesArray = $file -split "/" 
                $foldersNameCount = ($file -split "/" |Measure).Count-2 

                For($i=0;$i-le $foldersNameCount;$i+=1)
                {
                    $LocalFolderPath += $FolderNamesArray[$i] + "/"
                }

                $actualFileName = $FolderNamesArray[$foldersNameCount+1]    
                New-Item -ItemType Directory -Force -Path $dateFolder/$filesharename/Modified/$LocalFolderPath
                Copy-Item $actualFileName $dateFolder/$filesharename/Modified/$LocalFolderPath -Force
            }
    }

    Foreach($file in $JobOutputCreated)
    {
        #to filter the folders that somehow come in this list generated.
        if(Get-AzStorageFile -ShareName $fileShareName -path $file |where {$_.GetType().Name -ne "CloudFileDirectory"})
        {
            [string]$LocalFolderPath =""
            Get-AzStorageFileContent -Path $file -ShareName $fileShareName -Force
            $FolderNamesArray = $file -split "/" 
            $foldersNameCount = ($file -split "/" |Measure).Count-2 
            For($i=0;$i-le $foldersNameCount;$i+=1)
            {
                $LocalFolderPath += $FolderNamesArray[$i] + "/"
            }
            Write-host "---"$LocalFolderPath
            $actualFileName = $FolderNamesArray[$foldersNameCount+1]
            write-host "actualfilename" $actualFileName
            New-Item -ItemType Directory -Force -Path $dateFolder/$filesharename/Created/$LocalFolderPath
            Copy-Item $actualFileName $dateFolder/$filesharename/Created/$LocalFolderPath -Force
        }
    }
 }#end of all shares

#install azcopy
wget -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux
mkdir azcopy_v10
tar -xf azcopy_v10.tar.gz -C azcopy_v10
cd  /azcopy_v10/azcopy_linux_amd64_10.3.3
#set the destination storage account context.
Set-AzCurrentStorageAccount -ResourceGroupName $storageAccountRGDest -StorageAccountName $storageAccountNameDest | Out-Null #to suppress output.
$sasToken = New-AzStorageContainerSASToken -Name "$destContainer" -Permission rwdl
./azcopy copy "/$dateFolder" "https://$storageAccountNameDest.blob.core.windows.net/$destContainer/$sasToken" --recursive=true

