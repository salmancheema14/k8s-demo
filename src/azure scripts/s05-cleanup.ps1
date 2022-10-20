
$resourceGroup="salman-k8s-demo"
$aksClusterName = "k8sdemocluster"

#delete the resource group. This should delete the ACR and the AKS Cluster
Remove-AzResourceGroup -Name $resourceGroup