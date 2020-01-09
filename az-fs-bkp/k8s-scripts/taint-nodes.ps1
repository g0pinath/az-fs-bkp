param($client_id, $client_secret, $tenant_id, $subscription_id, $aks_rg_name, $aks_name)
az login --service-principal --username $client_id --password $client_secret --tenant $tenant_id
az account set --subscription=$subscription_id    
az aks get-credentials --name $aks_name --resource-group $aks_rg_name
$nodes = kubectl get nodes -o name
$i=0
Foreach($node in $nodes)
{
    kubectl taint nodes $node nodename="cronjob-node$i":NoSchedule --overwrite
    $i+=1
}