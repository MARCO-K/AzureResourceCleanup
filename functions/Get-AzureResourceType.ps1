Function Get-AzureResourceType
{
  <#
      .Synopsis
      The cmdlet removes all Azure resources.
      .Description
      The cmdlet removes all Azure resources. It can exclude various resource types and check the expiredOn tag.
      .PARAMETER TenantID
      This parameter is the actual tenant id. This is a mandatory parameter.
      .Example
      Get-AzureResourceType -TenantID $TenantID
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
        Write-PSFMessage -Level Verbose -Message $Connection.Context -ModuleName 'AzureResourceCleanup'
    }
    process {
        $Providers = Get-AzResourceProvider -ListAvailable -Pre

        if($Providers) {
            $ResourceTypes =
            foreach($Provider in $Providers) {
                $Provider.ResourceTypes
            }
        }
    }
    end {
        $ResourceTypes
    }
}