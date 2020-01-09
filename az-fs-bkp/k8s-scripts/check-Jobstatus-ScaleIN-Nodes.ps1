
param($client_id, $client_secret, $tenant_id, $subscription_id, $aks_rg_name, $aks_name, $aks_infra_nodes_name, $aks_vmss_name)
az login --service-principal --username $client_id --password $client_secret --tenant $tenant_id
az account set --subscription=$subscription_id    
az aks get-credentials --name $aks_name --resource-group $aks_rg_name


    $podsJson = kubectl get pods -n dev -o json
    $podsJson = $podsJson | ConvertFrom-Json
    [array]$podJsonArr = $podsJson.items
    $numofPods = ($podJsonArr |Measure).count
    $numofPendingPods = $numofPods
    $numofPodsCompleted = 0
    write-output "total pods $numofPods"
    Function DeleteNode($nodeName)
    {
        kubectl delete node $nodeName #delete from k8s
        #find the VMSS node ID and then delete it from VMSS.
        $instanceIDs = (Get-AzVmssVM -ResourceGroupName $aks_infra_nodes_name  -VMScaleSetName $aks_vmss_name | Select InstanceID).InstanceID
        foreach($id in $instanceIDs) 
        { 
            $currentComputername = (Get-AzVmssVM -ResourceGroupName $aks_infra_nodes_name -VMScaleSetName $aks_vmss_name -InstanceId $id | Select OSProfile).OsProfile.ComputerName
            if($currentComputername -eq $nodename)
            {
                Remove-AzVmss -ResourceGroupName "$aks_infra_nodes_name" -VMScaleSetName "$aks_vmss_name" -InstanceId "$id" -Force
            }
        }
    }
    $timewaited = 0
do{
    $podsJson = kubectl get pods -n dev -o json
    $podsJson = $podsJson | ConvertFrom-Json
    [array]$podJsonArr = $podsJson.items
    Write-Output "in top of WhileLoop"
    Foreach($item in $podJsonArr)
    {
        $podName = $item.metadata.name
        #either a pod is running or not, if its running the state.terminated will not exist and running.startedat will give some value and vice versa.
        $podTerminatedReason =$item.status.containerStatuses.state.terminated.reason # if the pod finished then the status is completed and this property is returned.
        $podRunningStart = $item.status.containerStatuses.state.running.startedAt # if this string length is 0 then pod is finished.
        
        if($podTerminatedReason -eq "completed")
        {
            Write-Output "cronjob -- $podName --status is $podTerminatedReason"
            $numofPodsCompleted += 1
            Write-Output "numofPodsCompleted -- $numofPodsCompleted "
            $numofPendingPods = $numofPods - $numofPodsCompleted
            Write-Output "numofPodsCompleted -- $numofPendingPods"
            #if the pod is node0 then leave the node as it is or add it to the list of items to be deleted.     
            if($podName -notlike "*cronjob-node0-*")
            {
                [string]$nodeName = $item.spec.nodeName
                Write-Output "Going to remove node $nodeName"
                DeleteNode $nodeName
                Write-Output "Done removing node $nodeName"
            }     
            
        }elseif($podRunningStart.length -gt 0)
        {
            # do nothing, pod is running.
            Write-Output "pod started at  -- $podRunningStart --status is running"
        }   
           
        
    }
    start-sleep -s 10
    $timewaited += 1
    Write-output "end of while timewaited is $timewaited -- numbof pods pending is $numofPendingPods"
}while($timewaited -gt 300 -or $numofPendingPods -gt 0)
Write-Output "Total number pods to be deleted is $numofPods"
kubectl delete pods -n dev --all


Write-Output "all pods are complete, scaled back to 1"
