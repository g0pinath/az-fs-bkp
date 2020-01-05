
 
# Define Variables
$subscriptionName = "DCP-IT-IAAS-N-01"
$storageAccountRG = "AS-CN-DCP-D-FILEBOUND-RG"
$storageAccountName = "ascndcpfbstorage01"
$fileShareName = "test-fs-bkp"
$localPath = "c:\temp"
$vaultname = "ASCNDCPBKPVLT010" 
$targetRestoredFileShare = "testfs-bkp-restored"
$backupItemName = "AzureFileShare;"+ $fileShareName# example AzureFileShare;testfsbkp

# Select right Azure Subscription
Select-AzSubscription -SubscriptionName $SubscriptionName
 
Set-AzCurrentStorageAccount -ResourceGroupName $storageAccountRG -StorageAccountName $storageAccountName 
# Generate SAS URI
$SASURI = New-AzStorageShareSASToken  -ShareName "$fileShareName"  -Permission "rwd"
 
[string]$SasPrefix = "https://" + $storageAccountName + ".file.core.windows.net/"

[string]$FullSasURL = $SasPrefix + $fileShareName + $SASURI
# Upload File using AzCopy
azcopy copy $localPath $FullSasURL –-recursive

###################################
#Set RSV context
$vault = Get-AzRecoveryServicesVault -Name "$vaultName"
Set-AzRecoveryServicesAsrVaultContext -Vault $vault 
#make changes and then trigger an on-demand backup.
$afsContainer = Get-AzRecoveryServicesBackupContainer -FriendlyName "$storageAccountName" -ContainerType AzureStorage -VaultId $vault.id
$afsBkpItem = Get-AzRecoveryServicesBackupItem -Container $afsContainer -WorkloadType "AzureFiles" -Name "$backupItemName"
$job =  Backup-AzRecoveryServicesBackupItem -Item $afsBkpItem -BackupType Differential

$afsContainer = Get-AzRecoveryServicesBackupContainer -FriendlyName "$storageAccountName" -ContainerType AzureStorage -VaultId $vault.id
$afsBkpItem = Get-AzRecoveryServicesBackupItem -Container $afsContainer -WorkloadType "AzureFiles" -Name "$backupItemName"

$startDate = (Get-Date).AddDays(-1)
$endDate = Get-Date
$rp = Get-AzRecoveryServicesBackupRecoveryPoint -Item $afsBkpItem -StartDate $startdate.ToUniversalTime() -EndDate $enddate.ToUniversalTime()
$dateFolder = get-date -Format yyyyddMM
Restore-AzRecoveryServicesBackupItem -RecoveryPoint $rp[0] -TargetStorageAccountName "$storageAccountName" -TargetFileShareName "$targetRestoredFileShare" -TargetFolder "restored/$datefolder-1" -ResolveConflict Overwrite

