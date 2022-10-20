
$subscription="0d13d072-64ed-4c78-b54a-31a7fab3ad01"
$resourceGroup="salman-k8s-demo"
$resourceGroupLocation="eastus"

$containerRegistryName="k8sdemosalman"
$aksClusterName = "k8sdemocluster"

#create the test resource group 
New-AzResourceGroup -Name $resourceGroup -Location $resourceGroupLocation
Write-Host "Successfully created ResourceGroup: $($resourceGroup)"
Start-Sleep -Seconds 5

# create container registry
$registry = New-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $containerRegistryName -EnableAdminUser -Sku Basic
Start-Sleep -Seconds 5

#The Get-AzContainerRegistry should return "LoginSucceeded" once the registry creation is complete
Connect-AzContainerRegistry -Name $registry.Name
$acrLoginServer = (Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $containerRegistryName).LoginServer

Write-Host "Successfully created ACR: '$($containerRegistryName)' in resource group '$($resourceGroup)'"
Write-Host "Login Server for ACR: '$($acrLoginServer)'"
