# k8s-demo

This repo has instructions to prepare your machine and create appropriate Azure resources, for the tutorial session on docker and Kubernetes.

## Pre-Requisites

### Create Azure resources and install kubectl on your dev-box 
1. Create a `.ssh\` folder on your Windows machine under `c:\Users\<username>\`. This is necessary for AKS cluster deployments (with SSH keys). There appears to be an open issue where including a `--generate-ssh-keys` parameter via Azure CLI always throws an error.
2. Clone this repository on your machine.
3. Install Azure CLI on your machine, if you do not already have it. [Install Link] (https://learn.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-9.0.1)
4. Modify the *<github_repo_path>\src\azure scripts\1-create-resources.ps1* script to provide unique names for resource group, container registry, and AKS cluster resources. 
5. Open a windows powershell window in **Administrator** mode, and execute the *<github_rep_path>\src\azure scripts\1-create-resources.ps1* script. *This script can run for 15-20 minutes*. 
6.  While running the script, powershell may complain about the script being unsigned. You can get around this by executing `Set-ExecutionPolicy -ExecutionPolicy unrestricted` in the powershell window. Re-run the script after changing the execution policy.
7. Once the script completes, you should be able to view the following resources under your chosen resource group in Azure Portal: *Azure Container Registry*, *Azure Kubernetes Service Cluster(with 2 Nodes)*
8. The script also installs `kubectl` on your windows machine, under `C:\Users\<username>\.azure-kubectl\`. *You will need to manually add this folder to the system PATH environment variable*. After changing the path variable, you will need to close and re-open any terminal windows, for the change to take effect.

***Verifying Correct Configuration***    
If everything is configured correctly, you can use `kubectl` to manage your AKS cluster.   
Try out the following commands
```
kubectl cluster-info
kubectl api-resources
kubectl get nodes
kubectl describe nodes
```

### Setup Docker on WSL2/Ubuntu

Configure your instance of WSL to default to version 2 and configure Ubuntu
```
wsl --set-default-version 2
wsl --install -d ubuntu 
```

From your ubuntu VM's terminal, run the following commands to install Docker CLI (and its dependencies)
```
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

You can now run `sudo usermod -aG docker $USER && newgrp docker` to make your life slightly easier. This will eliminate the need to always append `sudo` with each `docker` command.

**Verifying Docker Installation**    
Try printing out the docker version `docker --version`.    
You can also run the docker hello world container, using `docker run hello-world`.     
If you get an error about docker not running or being stopped, you can manually start it using `sudo service docker start`.


### Install Azure CLI on your Ubuntu VM in WSL2

From the ubuntu VM's terminal, run the following commands to install Azure CLI. This is necessary to push docker images to Azure Container Registry.
```
sudo apt-get update
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
sudo apt-get install azure-cli
```

**Verifying Azure CLI Installation**    
Run the following commands
```
sudo az login
sudo az acr login --name <NAME_OF_YOUR_CONTAINER_REGISTRY_CREATED_EARLIER>
```
If Azure CLI is configured correctly, you will see a *Login Successful* message when logging into the Container Registry with the second command.

---

## Docker Images and Containers

### How to build and run docker containers locally

This repo contains a very small node.js application, under `<path of git repo>/src/demo-app`.    
You can build a docker image for this application by executing 
```
docker build -t demo-app .
```
This builds the image and adds it to the local image store in your VM. You can see a list of available docker images by running `docker images`.    

You can run the docker image locally by executing 
```
docker run --name demo-container -p 8080:8080 -d demo-app
```
This command instructs docker to run a container, called *demo-container*, built from the *demo-app* image. The second part of the command, `-p 8080:8080` maps the 8080 port on your local machine to the 8080 port on the container.     
You can verify the behavior of the application by either opening `localhost:8080` in your browser or running `curl localhost:8080` in the VM terminal.

Here are a few other docker commands to try out
* Get all containers: `docker ps`
* Inspect a container: `docker inspect demo-container`
* Stop a running container: `docker stop demo-container`
* View all containers (including stopped ones): `docker ps -a`
* Remove a container from local image store: `docker rm demo-container`

### How to publish docker containers to Azure Container Registry
You will need your ACR's `loginServer` name. You can read this from the Azure portal.   

1. Build the image (if you removed it from the local image store): 	`docker build -t demo-app .`
2. Tag image with the name of loginServer, and append image version number: `docker tag demo-app <loginServer>.azurecr.io/demo-app:v1`
3. Use `docker images` to verify that a duplicate entry for the newly tagged image has appeared in the local image store.
4. Push tagged image to Azure Container Registry.
```
sudo az login
sudo az acr login --name <CONTAINER_REGISTRY_NAME>
sudo docker push <loginServer>.azurecr.io/demo-app:v1
```
***For this demo, pushing via personal credentials will work because our entire team has 'Contributor' permissions on the chosen subscription. In production environment, we will lock down the container registry's access policies via Azure roles assigned to either service principals or managed identities.*** 


**Verifying Successful Image publication**    
* Open your Container Registry in Azure portal, and go to "repositories" section from left pane.
* A new repository should now be visible, with the same name as your published image.
* if you open the new repository, you should see the version tag that was created during publication.
* [optional extra] Modify the app.js file to append a timestamp to its responses, build and tag a v2 image, and push to the ACR.
* [experiment] you can also try to pull images from the Container Registry via docker, e.g., `docker pull <loginServer>.azurecr.io/demo-app:v1`

---
## Deploy Image from Container Registry to Kubernetes Cluster
First, verify `kubectl`'s connection to your AKS cluster, by running some of the following commands
```
kubectl cluster-info
kubectl get nodes
kubectl describe nodes	
```

1. Open the helm chart in this repo (`<github-repo-path>/src/helm/DemoService.yaml`) and modify its `image` field (line 19) to reflect your specific Container Registry and image, in the following format `<loginServer>.azurecr.io/demo-app:v1`.
2. The helm chart has two resource definitions: a [Deployment, with 3 pods] and a [Service]. 
3. Use `kubectl` to deploy the update helm chart
```
kubectl create -f <path to helm chart>/DemoService.yaml
```
You can also use `kubectl apply` instead of `kubectl create`. Create is similar to Http POST action, whereas Apply is similar to HTTP PUT.   

After deploying the helm chart, you can use the following commands to view details of the newly created resources (1 service, 1 deployment, 3 pods):
```
kubectl get pods
kubectl get pods -o wide
kubectl get deployments
kubectl get services
```

You can dig deeper into each resource by using `kubectl describe` commands: 
```
kubectl describe service "demo-service"
kubectl describe deployment "demo-app"
kubectl describe pod <PICK_A_POD_NAME_FROM_GET_PODS_COMMAND>
```

Similarly, you can use `kubectl explain` to view platform documentation. In the following example, `pod`, `pods`, and `deployment` are all specific kubernetes resources. You can get a full list of all supported resource types on your cluster by `kubectl api-resources'.
```
kubectl explain pods
kubectl explain pod.spec
kubectl explain deployment
kubectl explain deployment.status
kubectl explain deployment.spec
```

Some other `kubectl` commands to try out: 
```
kubectl get pods --all-namespaces
kubectl get pods --all-namespaces --show-labels
```

### Task: Figure out how to scale your deployment from 3 to 5 replicas
[kubectl cheatsheat](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---
## Cleanup

### Cleanup cluster deployments
```
kubectl delete service demo-service
kubectl delete deployment demo-app
```

### Close the Ubuntu VM's terminal and Unregister it
```
quit
wsl --unregister Ubuntu
```

### Delete the Resource Group created for this demo
You can do this via powershell (modify and run the `2-cleanup.ps1` script in this repo) or manually delete the resource group in the Azure Portal.
