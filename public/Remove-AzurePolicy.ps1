Function Remove-AzurePolicy
{
  <#
      .Synopsis
      The cmdlet removes Azure custom policies.
      .Description
      The cmdlet removes Azure custom policies incl. all assignments and definitions.
      .PARAMETER TenantID
      This parameter is the actual tenant id.
      .Example
      PS C:\> Remove-AzurePolicy $tenant = ''

  #>


  [cmdletbinding()]
  Param(
    [Parameter(Mandatory)]
    [string]$TenantID
  )
  begin {
    try
    {
      $Connection = Connect-AzAccount -TenantId $TenantID
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
    Write-Verbose -Message $Connection
    
    # Check and Register the resource provider if it's not already registered
    $AzProvider = Get-AzResourceProvider | Where-Object -FilterScript {
      $_.ProviderNamespace -eq 'Microsoft.PolicyInsights'
    }
    if ($AzProvider.RegistrationState -ne 'Registered') 
    {
      Register-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights'
    }
    
  }
  
  process {
    # Get the custom policy assignment
    $PolicyAss = Get-AzPolicyAssignment | Where-Object -FilterScript {
      $_.ResourceName -ne 'SecurityCenterBuiltIn'
    }
    # Removes the policy assignment
    $PolicyAss | Remove-AzPolicyAssignment

    # Get a reference to the custom policy initiatives
    $policies = Get-AzPolicySetDefinition  -Custom
    # Removes the custom policies
    if($policies) 
    {
      $policies | Remove-AzPolicySetDefinition -Confirm:$false
    }

    # Get a reference to the custom policy definition
    $policies = Get-AzPolicyDefinition | Where-Object -FilterScript {
      $_.Properties.PolicyType -eq 'Custom'
    }

    # Removes the custom policies
    if($policies) 
    {
      $policies | Remove-AzPolicyDefinition -Confirm:$false
    }
  }
    
  end { Disconnect-AzAccount }
}
