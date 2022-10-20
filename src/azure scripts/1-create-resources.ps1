$tenantId="72f988bf-86f1-41af-91ab-2d7cd011db47"
$cloudName="AzureCloud"
$subscription="0d13d072-64ed-4c78-b54a-31a7fab3ad01"
$resourceGroup="<your_name>-k8s"
$resourceGroupLocation="eastus"
$aksClusterName="k8s<your_name>"
$acrName="k8sdemo<your_name>"

az login --tenant $tenantId
az cloud set --name $cloudName
az account set --subscription $subscription

Write-Host "Successfully logged into $($cloudName), AAD tenant Id = '$($tenantId)', Current Subscription = '$($subscription)'"

Write-Host "Deploying Resource Group: $($resourceGroup)"
az group create --name $resourceGroup --location $resourceGroupLocation
Write-Host "Successfully created ResourceGroup: $($resourceGroup)"
Start-Sleep -Seconds 3

Write-Host "Deploying Container Registry: $($acrName)"
az acr create --resource-group $resourceGroup --name $acrName --sku Basic
Write-Host "Successfully created ACR: '$($acrName)' in resource group '$($resourceGroup)'"
Start-Sleep -Seconds 3

#IMPORTANT: create a '.ssh\' folder under 'C:\Users\<username\' to host the ssh keys. For some reason, 'az aks create' doesn't create this folder when --generate-ssh-keys is specified

Write-Host "Deploying AKS Cluster: $($aksClusterName)"
az aks create -n $aksClusterName -g $resourceGroup --enable-managed-identity --node-count 2 --generate-ssh-keys --attach-acr $acrName
Write-Host "Successfully created AKS Cluster: '$($aksClusterName)' in resource group '$($resourceGroup)'"
Start-Sleep -Seconds 3

Write-Host "Installing Kubectl and configuring kubectl context"
az aks install-cli
az aks get-credentials --resource-group $resourceGroup --name $aksClusterName
#the "aks install-cli" commands installs kubernetes, usually under 'C:\Users\<username>\.azure-kubectl'.
#IMPORTANT TO MANUALLY ADD THIS FOLDER TO 'PATH', using preferred method.