#Requires -Module @{ ModuleName = 'Az.Resources'; ModuleVersion = '6.4.0'}, @{ ModuleName = 'Az.Accounts'; ModuleVersion = '2.10.3'}

$tenant = '775fb56c-2847-4743-b9ff-51ffa2be3a64'
$expireOn = '2022-10-31'

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
$Connection

# Get all RG names
$RGs = (Get-AzResourceGroup).ResourceGroupName

foreach($RG in $RGs) 
{
  # Set Tag for RG
  Set-AzResourceGroup -ResourceId (Get-AzResourceGroup -Name $RG).ResourceId -Tag @{
    expireOn = $expireOn
  }

  $group = Get-AzResourceGroup -Name $RG
    
  # Get all resources in RG and add TAG
  $resources = Get-AzResource -ResourceGroupName $group.ResourceGroupName
  foreach ($r in $resources) 
  {
    # check if it is already tagged
    $tags = (Get-AzResource -ResourceId $r.ResourceId).Tags
    if ($tags) 
    {
      foreach ($key in $group.Tags.Keys) 
      {
        if (-not($tags.ContainsKey($key))) 
        {
          $tags.Add($key, $group.Tags.$key)
        }
      }
      Set-AzResource -Tag $tags -ResourceId $r.ResourceId -Force
    }
    else
    {
      Set-AzResource -Tag $group.Tags -ResourceId $r.ResourceId -Force
    }
  }
}
