$subscriptionName = "FREE TRIAL"
$storageAccountRG = "AZ-K8S-FSBKP"
$storageAccountName = "safsbkpsource"
$fileShareName = "src-fs"
$AllSubFoldersList =@()
$CurrSubFoldersListActual =@()


$folderPath = "even-files/temp"

[array]$JobDetails=@()

$client_id = "a6d4fa75-117e-478d-b370-a634f613b7a5"
$client_secret = "?Xjoi0AEVQ9ggNiLiQMtiB=D-GvEh03@"
$tenantId = "9deab971-f9a9-4f67-b314-d00630c8e2d4"

$passwd = ConvertTo-SecureString "$client_secret" -AsPlainText -Force
$pscredential = New-Object System.Management.Automation.PSCredential($client_id, $passwd)
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId | Out-Null

# Select right Azure Subscription
Select-AzSubscription -SubscriptionName $SubscriptionName | Out-Null

Set-AzCurrentStorageAccount -ResourceGroupName $storageAccountRG -StorageAccountName $storageAccountName | Out-Null #to suppress output.

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
$rootFolders = (Get-AzStorageFile -ShareName $fileShareName | where {$_.GetType().Name -eq "CloudFileDirectory"}).Name

Foreach($folder in $rootFolders)
{
    $AllSubFoldersList = GetSubFolders $folder
}
$AllSubFoldersList

