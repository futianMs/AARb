param (
    [Parameter(Mandatory=$true)]
    [string]
    $resourceGroup,

[Parameter(Mandatory=$true)]
    [string]
    $storageAccount,

[Parameter(Mandatory=$true)]
    [string]
    $storageAccountKey,

[Parameter(Mandatory=$true)]
    [string]
    $storageFileName,

[Parameter(Mandatory=$true)]
    [string]
    $userAssignedManagedIdentity
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with user-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
$identity = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroup -Name $userAssignedManagedIdentity -DefaultProfile $AzureContext
$AzureContext = (Connect-AzAccount -Identity -AccountId $identity.ClientId).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

#Set the parameter values for the Resource Manager template
$Parameters = @{
    "storageAccountType"="Standard_LRS"
    }

# Create a new context
$Context = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageAccountKey

Get-AzStorageFileContent -ShareName 'resource-templates' -Context $Context -path 'storageTemplate.json' -Destination 'C:\Temp' -Force

$TemplateFile = Join-Path -Path 'C:\Temp' -ChildPath $storageFileName

# Deploy the storage account
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroup -TemplateFile $TemplateFile -TemplateParameterObject $Parameters