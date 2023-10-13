Function Remove-AzureAllTag
{
  <#
    .Synopsis
    The cmdlet removes all tags on any ressources.
    
    .Description
    The cmdlet removes all tags on any ressources.
    
    .PARAMETER TenantID
    This parameter is the actual tenant id.
    
    .Example
    Remove-AzureExpiredTag $tenant = ''

  #>

  [cmdletbinding()]
  Param(
    [Parameter(Mandatory)]
    [string]$TenantID
  )

  begin {
    # check for existing connection to Azure
    $context = Get-AzContext -ListAvailable
    
    ## if no connection exists then try to connect
    if ($context.count -eq 0) 
    {
      try
      {
        $Connection = Connect-AzAccount -TenantId $TenantId
      }
      catch 
      {
        if (!$Connection)
        {
          Write-PSFMessage -Level Error -Message '... Connection not found.' -ModuleName 'AzureResourceCleanup'
          throw
        }
        else
        {
          Write-PSFMessage -Level Error -Message $_.Exception -ModuleName 'AzureResourceCleanup'
          throw
        }
      }
      Write-PSFMessage -Level Verbose -Message $Connection -ModuleName 'AzureResourceCleanup'
    }
    else 
    {
      $context = Get-AzContext
      Write-PSFMessage -Level Verbose -Message "All vaults in context $($context.name) will be removed" -ModuleName 'AzureResourceCleanup'
    }

    # Get all RG names
    $RGs = (Get-AzResourceGroup).ResourceGroupName
  }

  Process {
    foreach($RG in $RGs) 
    {
        $resources = Get-AzResource -ResourceGroupName $RG
        
        foreach ($resource in $resources) {
            Set-AzResource -ResourceId $resource.ResourceId -Tag @{} -Force
        }
    }
    # Remove tags for the resource group
    Set-AzResourceGroup -Name $ResourceGroupName -Tag @{} -force

  }

  end {
    Write-PSFMessage -Level Verbose -Message '... Removing all tags on all ressources.' -ModuleName 'AzureResourceCleanup'
    disconnect-AzAccount
  }
}