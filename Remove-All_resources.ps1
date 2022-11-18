#Requires -Module @{ ModuleName = 'Az.Resources'; ModuleVersion = '6.4.0'}, @{ ModuleName = 'Az.Accounts'; ModuleVersion = '2.10.3'}, @{ ModuleName = 'Az.ResourceGraph'; ModuleVersion = '0.13.0'}

$tennant = '775fb56c-2847-4743-b9ff-51ffa2be3a64'
$exclude = ('Microsoft.RecoveryServices', 'Microsoft.StorageSync')

try
{
  # Get the connection "AzureRunAsConnection "
  $Connection = Connect-AzAccount -TenantId $tennant
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
  $index = 0..($array.Length -1) | Where-Object { $array[$_] -notin $exclude }
  if($index -gt 0) { $resourceID }
}


## Collect all expired resources
$expResources = Search-AzGraph -Query 'where todatetime(tags.expireOn) < now() | project id'

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
      Remove-AzResource -ResourceId $res -Force -WhatIf ## -WhatIf #REMOVE THE WHATIF TO REALLY DELETE RESOURCES
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
    $count = (Get-AzResource | Where-Object { $_.ResourceGroupName -match $RGname }).Count

    # now remove empty RGs
    if($count -eq 0)
    {
      Remove-AzResourceGroup -Name $RGname -Force -WhatIf ##-WhatIf #REMOVE THE WHATIF TO REALLY DELETE RESOURCES
    }
  }
}
$result