Function Unlock-AzureLockedResource
{
  <#
      .Synopsis
      The cmdlet removes locks form ALL Azure locked resources.
      
      .Description
      The cmdlet removes locks form ALL Azure locked resources.
      
      .PARAMETER TenantID
      This parameter is the actual tenant id.
  
      .Example
      Unlock-AzureLockedResource -TenantID $TenantID
  #>

  [cmdletbinding()]
  Param(
    [Parameter(Mandatory)]
    [string]$TenantID
  )

  begin {
    #connect to AZ account
    try
    {
      $Connection = 
      if ($subscritionID) {
        Connect-AzAccount -TenantId $TenantID -Subscription $subscritionID
      }
      else  {
        Connect-AzAccount -TenantId $TenantID
      }
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
        Write-PSFMessage -level Error -Message $_.Exception.Message -ModuleName 'AzureResourcecleanup'
        throw $_.Exception
      }
    }
    Write-PSFMessage -Level 'Verbose' -Message "Processing: $($Connection.Context.Subscription.Name)" -ModuleName 'AzureResourcecleanup'
    
     
    # Get all locked resources
    $lockedResources = Get-AzResourceLock
  }

  process {
    # Remove all locks
    foreach ($lockedResource in $lockedResources) {
      Write-PSFMessage -Level Verbose -Message "Removing lock on resource: $($lockedResource.ResourceName)" -ModuleName 'AzureResourcecleanup'
      $lockedResource | Remove-AzResourceLock -Force
    }
  }

  end {
    Write-PSFMessage -Level Verbose -Message 'All locks removed...' -ModuleName 'AzureResourcecleanup'
  }
}