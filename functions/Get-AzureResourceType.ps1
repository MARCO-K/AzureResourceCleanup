Function Get-AzureResourceType
{
  <#
      .Synopsis
      The cmdlet removes all Azure resources.
    
      .Description
      The cmdlet removes all Azure resources. It can exclude various resource types and check the expiredOn tag.
      
     .PARAMETER TenantID
      This parameter is the actual tenant id. This is a mandatory parameter.

      .PARAMETER Registered
      This parameter is used to filter only registered resources.
    
      .Example
      Get-AzureResourceType -TenantID $TenantID
  #>

  [cmdletbinding()]
  Param(
    [Parameter(Mandatory)]
    [string]$TenantID,
    [switch]$Registered
  )

  begin {
    #connect to AZ account
    try
    {
       $connection = Connect-AzAccount -TenantId $TenantID
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
        Write-PSFMessage -Level Error -Message $_.Exception.Message -ModuleName 'AzureResourceCleanup'
        throw $_.Exception
      }
    }
        Write-PSFMessage -Level Verbose -Message "Will process subscription: $($Connection.Context.Subscription.Name)" -ModuleName 'AzureResourceCleanup'
    }
    process {
        Write-PSFMessage -Level Verbose -Message 'Retrieve all Resource provider...' -ModuleName 'AzureResourceCleanup'
        $Providers = Get-AzResourceProvider -ListAvailable -Pre

        if($Providers) {
            Write-PSFMessage -Level Verbose -Message 'Retrieve all Resource types for any provider...' -ModuleName 'AzureResourceCleanup'
            $ResourceTypes =
            foreach($Provider in $Providers) {
                $Provider.ResourceTypes | ForEach-Object {
                    [PSCustomObject]@{
                        ProviderNamespace = $Provider.ProviderNamespace
                        ResourceTypeName = $_.ResourceTypeName
                        Locations = $_.Locations
                        ApiVersions = $_.ApiVersions
                        RegistrationState = $Provider.RegistrationState
                    }
                }

            }
        }
    }
    end {
        Write-PSFMessage -Level Verbose -Message 'Output all Resource types...' -ModuleName 'AzureResourceCleanup'
        if($Registered) {
            $ResourceTypes = $ResourceTypes | Where-Object { $_.RegistrationState -eq 'Registered' }    
        }
        $ResourceTypes
    }
}