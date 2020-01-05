$subscriptionName = "FREE TRIAL"
$storageAccountRG = "AZ-K8S-FSBKP"
$storageAccountName = "safsbkpsource"
$fileShareName = "src-fs"
$localPath = "c:\temp"

$client_id = "a6d4fa75-117e-478d-b370-a634f613b7a5"
$client_secret = "?Xjoi0AEVQ9ggNiLiQMtiB=D-GvEh03@"
$tenantId = "9deab971-f9a9-4f67-b314-d00630c8e2d4"

$passwd = ConvertTo-SecureString "$client_secret" -AsPlainText -Force
$pscredential = New-Object System.Management.Automation.PSCredential($client_id, $passwd)
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId

# Select right Azure Subscription
Select-AzSubscription -SubscriptionName $SubscriptionName
Set-AzCurrentStorageAccount -ResourceGroupName $storageAccountRG -StorageAccountName $storageAccountName | Out-Null #to suppress output.

# Generate SAS URI
$SASURI = New-AzStorageShareSASToken  -ShareName "$fileShareName"  -Permission "rwd"
[string]$SasPrefix = "https://" + $storageAccountName + ".file.core.windows.net/"
[string]$FullSasURL = $SasPrefix + $fileShareName + $SASURI
$SasPrefix + $fileShareName + $SASURI
# Upload File using AzCopy

azcopy copy $localPath $FullSasURL --recursive
#AzCopy copy https://safsbkpsource.file.core.windows.net/src-fs/temp?sv=2019-02-02&ss=bfqt&srt=sco&sp=rwdlacup&se=2019-12-28T18:41:24Z&st=2019-12-28T10:41:24Z&spr=https&sig=d4N83%2B%2FzsD2PeX3SMN87nk75lcQdCaxn026eJwNXQPM%3D https://safsbkpsource.file.core.windows.net/src-fs-1?sv=2019-02-02&ss=bfqt&srt=sco&sp=rwdlacup&se=2019-12-28T18:41:24Z&st=2019-12-28T10:41:24Z&spr=https&sig=d4N83%2B%2FzsD2PeX3SMN87nk75lcQdCaxn026eJwNXQPM%3D --recursive