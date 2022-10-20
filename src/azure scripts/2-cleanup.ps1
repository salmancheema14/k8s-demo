
$resourceGroup="<your_name>-k8s"

#delete the resource group. This should delete the ACR and the AKS Cluster
Remove-AzResourceGroup -Name $resourceGroup