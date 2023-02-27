#requires -module @{ModuleName = 'Az.Resources';Version = '6.4.0'}
#requires -module @{ModuleName = 'Az.Accounts';Version = '2.10.3'}



Function Remove-Azurepolicy {

<#
  .Synopsis
    <short description>
  .Description
    <long description>
  .Example
    PS C:\> Remove-Azurepolicy
    <output and explanation>
  .Inputs
    <Inputs to this function (if any)>
  .Outputs
    <Output from this function (if any)>
  .Notes
    <General notes>
  .Link
    <enter a link reference>
#>


	[cmdletbinding()]
	Param()
$tenant = '775fb56c-2847-4743-b9ff-51ffa2be3a64'
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
$AzProvider = Get-AzResourceProvider | Where-Object -FilterScript {
  $_.ProviderNamespace -eq 'Microsoft.PolicyInsights' 
}
if ($AzProvider.RegistrationState -ne 'Registered') 
{
  Register-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights'
}
$PolicyAss = Get-AzPolicyAssignment | Where-Object -FilterScript {
  $_.ResourceName -ne 'SecurityCenterBuiltIn'
}
$PolicyAss | Remove-AzPolicyAssignment
$policies = Get-AzPolicySetDefinition  -Custom
if($policies) 
{
  $policies | Remove-AzPolicySetDefinition -Confirm:$false
}
$policies = Get-AzPolicyDefinition | Where-Object -FilterScript {
  $_.Properties.PolicyType -eq 'Custom'
}
if($policies) 
{
  $policies | Remove-AzPolicyDefinition -Confirm:$false
}
Disconnect-AzAccount

} #close Remove-Azurepolicy
