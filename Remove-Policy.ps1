#Requires -Module @{ ModuleName = 'Az.Resources'; ModuleVersion = '6.4.0'}, @{ ModuleName = 'Az.Accounts'; ModuleVersion = '2.10.3'}

$tenant = '775fb56c-2847-4743-b9ff-51ffa2be3a64'

# Get the context
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

# Check and Register the resource provider if it's not already registered
$AzProvider = Get-AzResourceProvider | Where-Object { $_.ProviderNamespace -eq 'Microsoft.PolicyInsights' }
if ($AzProvider.RegistrationState -ne 'Registered') { 
Register-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights'}

# Get the custom policy assignment
$PolicyAss = Get-AzPolicyAssignment | Where-Object { $_.ResourceName -ne 'SecurityCenterBuiltIn'}
# Removes the policy assignment
$PolicyAss | Remove-AzPolicyAssignment

# Get a reference to the custom policy initiatives
$policies = Get-AzPolicySetDefinition  -Custom
# Removes the custom policies
if($policies) { 
  $policies | Remove-AzPolicySetDefinition -Confirm:$false
}

# Get a reference to the custom policy definition
$policies = Get-AzPolicyDefinition | Where-Object {$_.Properties.PolicyType -eq 'Custom'}

# Removes the custom policies
if($policies) { 
  $policies | Remove-AzPolicyDefinition -Confirm:$false
}




