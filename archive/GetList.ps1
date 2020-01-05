param(
[string]$subscriptionName,
[string]$storageAccountRG,
[string]$storageAccountName,
[string]$fileShareName,
[string]$tenantId,
[string]$client_id,
[string]$client_secret
)



$subscriptionName = "FREE TRIAL"
$storageAccountRG = "AZ-K8S-FSBKP"
$storageAccountName = "safsbkpsource"
$fileShareName = "src-fs"
[int]$batchSize = 1000 ###should be 1000
#[datetime]$timecus = (Get-Date).adddays(-1).ToUniversalTime()
[datetime]$timecus = (Get-Date).addhours(-1).ToUniversalTime()

[array]$JobDetails=@()
$JobOutputModified = @()
$JobOutputCreated = @()

$client_id = "a6d4fa75-117e-478d-b370-a634f613b7a5"
$client_secret = "?Xjoi0AEVQ9ggNiLiQMtiB=D-GvEh03@"
$tenantId = "9deab971-f9a9-4f67-b314-d00630c8e2d4"

$passwd = ConvertTo-SecureString "$client_secret" -AsPlainText -Force
$pscredential = New-Object System.Management.Automation.PSCredential($client_id, $passwd)
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId |Out-Null

# Select right Azure Subscription
Select-AzSubscription -SubscriptionName $SubscriptionName |Out-Null
Set-AzCurrentStorageAccount -ResourceGroupName $storageAccountRG -StorageAccountName $storageAccountName | Out-Null #to suppress output.
$allShares = (Get-AzStorageshare |Select Name).Name

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

        if($files[$j].properties.creationtime.UTCDateTime -gt $timecus)
        {
           [string]$fullpath = $folderPath+ "/" + $files[$j].Name  
          # Write-Output $fullpath    
           $modifiedFilesList += $fullpath                 
        }
        elseif($files[$j].Properties.lastmodified.utcdatetime -gt $timecus)
        {
           [string]$fullpath = $folderPath+ "/" + $files[$j].Name  
          # Write-Output $fullpath    
           $createdFilesList += $fullpath                 
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
    $JobOutputModified
    $JobOutputCreated

    $dateFolder = get-date -Format yyyyMMdd
    New-Item -ItemType Directory $dateFolder/$filesharename/Modified -Force
    New-Item -ItemType Directory $dateFolder/$filesharename/Created -Force
    #Download the files and copy them locally with the same folder structure. This whole bundle can then be uploaded to BLOB as is.
    Foreach($file in $JobOutputModified)
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

    Foreach($file in $JobOutputCreated)
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
 }#end of all shares