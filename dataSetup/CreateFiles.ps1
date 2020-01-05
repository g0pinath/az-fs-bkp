$subscriptionName = "FREE TRIAL"
$storageAccountRG = "AZ-K8S-FSBKP"
$storageAccountName = "safsbkpsource"
$fileShareName = "src-fs"
$localPath = "c:\temp"

$client_id = ""
$client_secret = ""
$tenantId = ""

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