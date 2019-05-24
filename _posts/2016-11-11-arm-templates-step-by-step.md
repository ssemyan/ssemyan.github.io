---
layout: post
title: "Creating Azure Resources with ARM Templates Step by Step"
categories: DevOps
excerpt: "This article explains how to use PowerShell and ARM templates to build out a Linux VM and its associated components such as networking and security."
---
*The files used in this article can be found in GitHub here: [https://github.com/ssemyan/BasicAzureLinuxVmArmTemplate](https://github.com/ssemyan/BasicAzureLinuxVmArmTemplate){:target="_blank"}*

There are many ways to script the creation of virtual machines, services, and other resources in Azure. Available tools include PowerShell, cross-platform command line tools, and SDKs for Java, .NET and other languages. These resources can be found [here](https://azure.microsoft.com/en-us/downloads/){:target="_blank"}.

Azure Resource Manager (ARM) templates are a way of describing resources in JSON. These templates can be used by PowerShell or the command line tools to build out deployments including networking, services, VMs, etc.

This article explains in detail how to use PowerShell and ARM templates to build out a Linux VM and the associated components such as networking and security.

It is easy to script out an existing deployment in the Azure Portal. To do this, simply click on the *Automation* script link in the resource group's properties blade.

![Automation Script Blade in Azure Portal](/assets/images/arm-templates-step-by-step-1.png)

Doing this will generate a set of files you can use to recreate the contents of the resource group.

![Generated Template](/assets/images/arm-templates-step-by-step-2.png)

These files are a good start but if you want to create re-usable deployments you will want to edit them a bit. The files referenced in this article can be found on GitHub here: [https://github.com/ssemyan/BasicAzureLinuxVmArmTemplate](https://github.com/ssemyan/BasicAzureLinuxVmArmTemplate){:target="_blank"}

For deploying using PowerShell and JSON templates, there are three files: *deploy.ps1*, *parameters.json*, and *template.json*. We will go over each of these in detail.

The first file is the PowerShell deployment script *deploy.ps1* Looking at this file you will see this section first:

```
param(
 [Parameter(Mandatory=$True)]
 [string]
 $subscriptionId,

 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [string]
 $templateFilePath = "template.json",

 [string]
 $parametersFilePath = "parameters.json"
)
```

This section sets the command-line parameters for the script. *$subscriptionId* is the ID of subscription to use. Sometimes a login will have access to multiple subscriptions, so it is important to specify which subscription to use. *$resourceGroupName* is the name of the resource group to create. This name is also used to name some of the shared components like the storage account and virtual network (vnet). Resource groups can be thought of as folders that make it easy to organize and manage groups of related resources. *$templateFilePath* and *$parametersFilePath* indicate which files to use for the deployment. We will cover these files in depth a bit later. For now, just know that by default we use *template.json* and *parameter.json* but you can override this by passing in different values.

To run the deployment script you therefore must enter a subscription ID, a resource group name and, optionally, the name of the parameter and template files to use if you want to use files other than the default.

When calling the script from within PowerShell, simply enter the script filename and the parameters:

```
PS C:\source> .\deploy.ps1 -subscriptionId f061aa2a-50c2-46a0-818b-6a5829ff5a70 -resourceGroupName mygroup
```

From a command prompt, you will need to invoke PowerShell like so:

```
C:\source> powershell -f deploy.ps1 -subscriptionId f061aa2a-50c2-46a0-818b-6a5829ff5a70 -resourceGroupName mygroup
```

The line of the deployment script states that the script should stop on any errors. And then the script logs into Azure using the supplied subscription ID

```
$ErrorActionPreference = "Stop"

# sign in and select subscription
Write-Host "Logging in...";
Login-AzureRmAccount -SubscriptionID $subscriptionId;
```

In the next section, we load the parameters file into a variable so we can use it within the script. This allows us to use some of the parameters within the script such as the location for the resources.

```
# load the parameters so we can use them in the script
$params = ConvertFrom-Json -InputObject (Gc $parametersFilePath -Raw)
```

Now we are ready to start creating resources in Azure. First, we create the resource group unless it already exists.

```
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Creating resource group '$resourceGroupName' in location $params.parameters.location.value";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $params.parameters.location.value -Verbose 
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}
```

Next, before we create the resources in our resource group, we do a test deployment to ensure the parameter and template files are correct and that the resources can be created.

```
# Test
Write-Host "Testing deployment...";
$testResult = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -ErrorAction Stop;
if ($testResult.Count -gt 0)
{
	write-host ($testResult | ConvertTo-Json -Depth 5 | Out-String);
	write-output "Errors in template - Aborting";
	exit;
}
```

Note that if we find errors, we print them to the screen in JSON format with the depth set to 5 levels deep so that we can see any nested errors in plain text. If there are no errors, we are ready to do the actual deployment.

```
# Start the deployment
Write-Host "Starting deployment...";
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Verbose;
```

The -Verbose flag will print information as the resources are created:

```
C:\source> powershell -f deploy.ps1 -subscriptionId cd82f777-1ae3-48fb-8887-05e9f88e3a33 -resourceGroupName mygroup
Logging in...

Environment           : AzureCloud
Account               : user@live.com
TenantId              : 5e8c4d9e-7f04-49c5-96d5-9b7b6c0a908c
SubscriptionId        : 3e898ccf-0dc8-4268-a935-2e260646258b
SubscriptionName      : Visual Studio Enterprise
CurrentStorageAccount :

Creating resource group 'mygroup' in location centralus
VERBOSE: Performing the operation "Replacing resource group ..." on target "".
VERBOSE: 11:30:54 AM - Created resource group 'mygroup' in location 'centralus'

ResourceGroupName : mygroup
Location          : centralus
ProvisioningState : Succeeded
Tags              :
TagsTable         :
ResourceId        : /subscriptions/3e898ccf-0dc8-4268-a935-2e260646258b/resourceGroups/mygroup

Testing deployment...
Starting deployment...
VERBOSE: Performing the operation "Creating Deployment" on target "mygroup".
VERBOSE: 11:30:57 AM - Template is valid.
VERBOSE: 11:30:59 AM - Create template deployment 'template'
VERBOSE: 11:30:59 AM - Checking deployment status in 5 seconds
VERBOSE: 11:31:04 AM - Resource Microsoft.Storage/storageAccounts 'mygroupstorage6t6' provisioning status is running
VERBOSE: 11:31:04 AM - Resource Microsoft.Network/publicIpAddresses 'mygroup-chefsvr-ip' provisioning status is running
VERBOSE: 11:31:04 AM - Resource Microsoft.Network/networkSecurityGroups 'mygroup-nsq' provisioning status is running
VERBOSE: 11:31:04 AM - Resource Microsoft.Network/virtualNetworks 'mygroup-vnet' provisioning status is running
VERBOSE: 11:31:04 AM - Checking deployment status in 10 seconds
VERBOSE: 11:31:14 AM - Resource Microsoft.Network/networkSecurityGroups 'mygroup-nsq' provisioning status is succeeded
VERBOSE: 11:31:14 AM - Resource Microsoft.Network/virtualNetworks 'mygroup-vnet' provisioning status is succeeded
VERBOSE: 11:31:15 AM - Checking deployment status in 15 seconds
VERBOSE: 11:31:30 AM - Resource Microsoft.Compute/virtualMachines 'chefsvr' provisioning status is running
VERBOSE: 11:31:30 AM - Resource Microsoft.Storage/storageAccounts 'mygroupstorage6t6' provisioning status is succeeded
VERBOSE: 11:31:30 AM - Resource Microsoft.Network/networkInterfaces 'chefsvrnic' provisioning status is succeeded
VERBOSE: 11:31:30 AM - Resource Microsoft.Storage/storageAccounts 'mygroupstorage6t6' provisioning status is succeeded
VERBOSE: 11:31:30 AM - Resource Microsoft.Network/publicIpAddresses 'mygroup-chefsvr-ip' provisioning status is succeeded
VERBOSE: 11:31:30 AM - Checking deployment status in 20 seconds
VERBOSE: 11:31:50 AM - Checking deployment status in 25 seconds
VERBOSE: 11:32:16 AM - Checking deployment status in 30 seconds
VERBOSE: 11:32:46 AM - Checking deployment status in 35 seconds
VERBOSE: 11:33:22 AM - Checking deployment status in 40 seconds
VERBOSE: 11:34:02 AM - Checking deployment status in 45 seconds
VERBOSE: 11:34:47 AM - Checking deployment status in 50 seconds
VERBOSE: 11:35:38 AM - Checking deployment status in 55 seconds
VERBOSE: 11:36:33 AM - Checking deployment status in 60 seconds
VERBOSE: 11:37:33 AM - Resource Microsoft.Compute/virtualMachines 'chefsvr' provisioning status is succeeded
```

Now, let’s turn our attention to the parameter and template files. These files are in JSON format and are used to store two types of settings. The template file describes the components and how they relate to each other. Generally, this file is not expected to change from deployment to deployment. The parameters file holds the settings that are specific to each deployment. This might include VM names, usernames, passwords or SSH keys, etc.

Let’s take a close look at each of these files. Looking first at the template file, at the beginning you will see the list of parameters:

```
"parameters": {
    "location": {
      "type": "string",
      "metadata": {
        "description": "Which region to use."
      }
    },
    "virtualMachineName": {
      "type": "string",
      "metadata": {
        "description": "Name for the Virtual Machine."
      }
    },
    "virtualMachineSize": {
      "type": "string",
      "metadata": {
        "description": "Size of the Virtual Machine."
      }
    },
    "adminUsername": {
      "type": "string",
      "metadata": {
        "description": "User name for the Virtual Machine."
      }
    },
    "adminPublicKey": {
      "type": "string",
      "metadata": {
        "description": "Public SSH Key for the Virtual Machine."
      }
    }
  },
```

Each parameter has a name, a type, and (optionally) a description. Because the parameters change per deployment you may have multiple parameter files, one for each type of VM you might want to create. Note that this example uses SSH keys instead of passwords. For more information on SSH key creation, see [Generating SSH keys for Azure Linux VMs](){:target="_blank"}

**Note:** putting passwords and SSH keys in plain text in parameter files is NOT a best practice. A better practice would be to place them in securestrings and pull values from the KeyVault at deploy time instead. This article keeps things simple, but more information on this topic can be found in [Create an SSL enabled Web server farm with VM Scale Sets](){:target="_blank"}

Next in the template file are variables. These are settings that are either calculated or are not changed for different deployments. You will notice the use of various functions such as concat, substring, uniquestring, etc. There are many functions which can be used in ARM templates and they are documented [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions){:target="_blank"}. The variable section for our file looks like this:

```
"variables": {
    "vnetId": "[resourceId(resourceGroup().name,'Microsoft.Network/virtualNetworks', variables('virtualNetworkName'))]",
    "subnetRef": "[concat(variables('vnetId'), '/subnets/', variables('subnetName'))]",
    "storageAccountName": "[concat(resourceGroup().name, 'storage', substring(uniquestring(resourceGroup().name),0,3))]",
    "virtualNetworkName": "[concat(resourceGroup().name, '-vnet')]",
    "networkInterfaceName": "[concat(parameters('virtualMachineName'), 'nic')]",
    "networkSecurityGroupName": "[concat(resourceGroup().name, '-nsq')]",
    "publicIpAddressName": "[concat(resourceGroup().name, '-', parameters('virtualMachineName'), '-ip')]",
    "storageAccountType": "Premium_LRS",
    "addressPrefix": "10.0.0.0/24",
    "subnetName": "default",
    "subnetPrefix": "10.0.0.0/24",
    "publicIpAddressType": "Dynamic"
  },
```

Some of these variables are just calculated values used during creation of the network or related resources. This includes *vnetId* and *subnetRef*. Another set of variables is for creating the names for shared resources within the resource group. The value for the *virtualNetworkName* for example is just the resource group name with "-vnet" appended to it. Thus, in resource group "mygroup" the vnet name will be "mygroup-vnet". Vnet names only have to be unique within a resource group. The *networkSecurityGroupName* is created similarly. The VM *networkInterfaceName* is created by joining the VM name with "nic" and the *publicIpAddressName* is created by joining the resource group name with the VM name and "-ip" to make what should be a unique name. Storage account names must also be unique. To create a unique name for *storageAccountName* we take the name of the resource group and then join it with a unique string based on the resource group name (the unique string is a hash of the text). We only take the first 3 characters and join them with the resource group name to create what should be a unique name for the storage account.

The rest of the variables are set here because they do not need to change from deployment to deployment. This includes the address prefixes for the net and subnet, the storage account type, the subnet name, and whether the public IP address is dynamic or static.

Now that we have parameters and variables, they can be referenced in the remainder of the template by doing this:

```
"[parameters('paramName')]"
```

or

```
"[variables('variableName')]"
```

Notice how they are enclosed in brackets. This tells the template processor to treat these as functions rather than literals. One item of note is that if you are using Visual Studio or VS Code you can get syntax completion in the template and parameter json files.

Now we are at the meat of the template file – the creation of resources. Each resource looks similar to this (for the Vnet):

```
{
      "name": "[variables('virtualNetworkName')]",
      "type": "Microsoft.Network/virtualNetworks",
      "apiVersion": "2016-09-01",
      "location": "[parameters('location')]",
      "properties": {
        "addressSpace": {
          "addressPrefixes": [
            "[variables('addressPrefix')]"
          ]
        },
        "subnets": [
          {
            "name": "[variables('subnetName')]",
            "properties": {
              "addressPrefix": "[variables('subnetPrefix')]"
            }
          }
        ]
      }
    },
```

Each resource has a name and a type. In the case above we are using the *virtualNetworkName* we created in the variables section for the resource of type: *Microsoft.Network/virtualNetworks*. The location comes from our parameters, and the rest of the required information comes from the variables we created. Every resource has an associated *apiVersion* that tells which version of the API the resource is available in. This setting can usually be left as generated from the Portal.

It is important that some resources are created before others. To enforce this use the dependsOn section in the resource. For example, before we can create the VM, we a storage account and the Vnet. Using dependsOn tells the script to not create the VM until both the storage account and the VNet have been created:

```
"dependsOn": [
        "[concat('Microsoft.Network/networkInterfaces/', variables('networkInterfaceName'))]",
        "[concat('Microsoft.Storage/storageAccounts/', variables('storageAccountName'))]"
      ],
```

The *New-AzureRmResourceGroupDeployment* cmdlet will not try to create resources that already exist. Thus, you can run a script over again without worry that it is creating copies of existing resources. This means you can run this script twice with two different parameter files describing two different VMs and you will create the associated storage account and vnet only once.

Hopefully this article has been useful in demystifying Azure ARM Templates. Automated and scripted deployments are critical for creating cloud infrastructure quickly and in a repeatable fashion. ARM templates are a useful way of describing your infrastructure as code.

A great resource with many examples of ARM templates is the Azure Quickstart Template project on GitHub: [https://github.com/Azure/azure-quickstart-templates](https://github.com/Azure/azure-quickstart-templates){:target="_blank"} This is the place to go to see how to create various resource scenarios with ARM templates. 

The files used in this article can be found in GitHub here: [https://github.com/ssemyan/BasicAzureLinuxVmArmTemplate](https://github.com/ssemyan/BasicAzureLinuxVmArmTemplate){:target="_blank"}
