#Requires -Module @{ ModuleName = 'Az.Resources'; ModuleVersion = '6.4.0'}, @{ ModuleName = 'Az.Accounts'; ModuleVersion = '2.10.3'}, @{ ModuleName = 'Az.ResourceGraph'; ModuleVersion = '0.13.0'}

$tenant = '775fb56c-2847-4743-b9ff-51ffa2be3a64'
$exclude = ('Microsoft.RecoveryServices', 'Microsoft.StorageSync')
$resourceGraphQuery = 'Resources | where todatetime(tags.expireOn) < now() | project id'

#create a custom exception to handle a Graph Resource error as a standard PowerShell exception
class AzResourceGraphException : Exception {
  [string] $additionalData

  AzResourceGraphException($Message, $additionalData) : base($Message) 
  {
    $this.additionalData = $additionalData
  }
}

$context = Get-AzContext
if ($context.Tenant.Id -ne $tenant) 
{
  # Get the connection
  try
  {
    $Connection = Connect-AzAccount -TenantId $tenant
  }
  catch 
  {
    if (!$Connection)
    {
      $ErrorMessage = '... Connection not found.'
      throw $ErrorMessage
    }
    else
    {
      Write-Error -Message $_.Exception
      throw $_.Exception
    }
  }
}
$Connection

<#
    Helper function to resolve resourceIds
    $resourceID = '/subscriptions/00/resourcegroups/rg-test/providers/microsoft.compute/virtualmachines/vm-test'
#>
function Select-GroupAndName
{
  param (
    [Parameter(Mandatory)][string]$resourceID
  )
  $array = $resourceID.Split('/') 
  $index = 0..($array.Length -1) | Where-Object -FilterScript {
    $array[$_] -notin $exclude
  }
  if($index -gt 0) 
  {
    $resourceID
  }
}



## Collect all expired resources
#Limit search to one subscription by changing the PowerShell profile
$PSDefaultParameterValues = @{
  'Search-AzGraph:Subscription' = $(Get-AzSubscription).ID
}

try 
{
  $expResources = Search-AzGraph -Query $resourceGraphQuery -ErrorVariable grapherror -ErrorAction SilentlyContinue 

  if ($null -ne $grapherror.Length) 
  {
    $errorJSON = $grapherror.ErrorDetails.Message | ConvertFrom-Json

    throw [AzResourceGraphException]::new($errorJSON.error.details.code, $errorJSON.error.details.message)
  }
}
catch [AzResourceGraphException] 
{
  Write-Verbose -Message 'An error on KQL query'
  Write-Verbose -Message $_.Exception.message
  Write-Verbose -Message $_.Exception.additionalData
}
catch 
{
  Write-Verbose -Message 'An error occurred in the script'
  Write-Verbose -Message $_.Exception.message
}

# exclude resources with special handling ;-)
$expResources = 
foreach($res in $expResources) 
{
  Select-GroupAndName -resourceID $res.ResourceId
}


if($expResources.Count -gt 0) 
{ 
  $result = 
  foreach ($res in $expResources) 
  {
    # Remove every single resource
    try 
    {
      Remove-AzResource -ResourceId $res -Force -Verbose ##-WhatIf ## -WhatIf #REMOVE THE WHATIF TO REALLY DELETE RESOURCES
    }
    catch 
    {
      Write-Error -Message $_.Exception
    }
  }

  $RGs = Get-AzResourceGroup
 
  foreach($RG in $RGs)
  {
    $RGname = $RG.ResourceGroupName
    $count = (Get-AzResource | Where-Object -FilterScript {
        $_.ResourceGroupName -match $RGname
    }).Count

    # now remove empty RGs
    if($count -eq 0)
    {
      Remove-AzResourceGroup -Name $RGname -Force ##-WhatIf ##-WhatIf #REMOVE THE WHATIF TO REALLY DELETE RESOURCES
    }
  }
}
$result