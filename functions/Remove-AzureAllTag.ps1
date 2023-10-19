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
    Remove-AzureAllTag $tenant = ''

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
    $RGs = Get-AzResourceGroup
  }

  Process {
    if($RGs){
      foreach($RG in $RGs) 
      {
          $resources = Get-AzResource -ResourceGroupName $RG.ResourceGroupName
          
          foreach ($resource in $resources) {
              Write-PSFMessage -Level Verbose -Message "Removing tags on $($resource.Name)" -ModuleName 'AzureResourceCleanup'
              Set-AzResource -ResourceId $resource.ResourceId -Tag @{} -Force
          }
      }
      # Remove tags for the resource group
      $null = Set-AzResourceGroup -Name $RG.ResourceGroupName -Tag @{}
    }
  }

  end {
    Write-PSFMessage -Level Verbose -Message '... Removing all tags on all ressources.' -ModuleName 'AzureResourceCleanup'
    disconnect-AzAccount
  }
}