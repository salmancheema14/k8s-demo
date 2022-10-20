
$resourceGroup="salman-k8s-demo"
$containerRegistryName="k8sdemosalman"
$aksClusterName = "k8sdemocluster"

#create the aks cluster
#The -AcrNameToAttach parameter will configure 'AcrPull' permissions on our ACR for the cluster's managed identity
New-AzAksCluster -ResourceGroupName $resourceGroup -Name $aksClusterName -NodeCount 2 -GenerateSshKey -AcrNameToAttach $containerRegistryName

#wait a while. Creating an AKS cluster resource can take some time.
#A new resource group will be created in the subscription to host the actual resources.

#Take a look at the azure portal to make sure that your AKS cluster deployment is complete