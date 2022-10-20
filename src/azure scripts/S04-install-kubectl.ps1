
#Use either cloud shell or your local powershell to play around in your cluster
#Azure cloud shell already includes kubectl: https://shell.azure.com/ or open from portal
#skip to line 14 if using cloud shell

$resourceGroup="salman-k8s-demo"
$aksClusterName = "k8sdemocluster"

#if using powershell, you will have to install kubectl and connect it with your newly created cluster
Install-AzAksKubectl
Import-AzAksCredential -ResourceGroupName $resourceGroup -Name $aksClusterName

#you can now use kubectl to manage the cluster, e.g., 
kubectl get nodes