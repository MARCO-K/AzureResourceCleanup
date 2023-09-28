Function Remove-AzureAllResources
{
  <#
      .Synopsis
      The cmdlet removes all Azure resources.
      .Description
      The cmdlet removes all Azure resources. It can exclude various resource types and check the expiredOn tag.
      .PARAMETER TenantID
      This parameter is the actual tenant id.
      .PARAMETER SubscritionID
      This parameter is the actual subscription id.
      .PARAMETER Exclude
      This parameter can be used to exclude several resource types. Possible exclusions are: 'Microsoft.RecoveryServices','Microsoft.StorageSync','Microsoft.Compute','Microsoft.Storage'.
      .Parameter checkexpireOn
      This parameter can be used to check the ExpireOn tag.
      .Example
      Remove-AzurePolicy TenantID $TenantID -SubscritionID $SubscritionID -checkexpireOn

  #>

  [cmdletbinding()]
  Param(
    [Parameter(Mandatory)]
    [string]$TenantID,
    [ValidateScript({
          $Subscriptions = ((Get-AzContext).Account | Select-Object -ExpandProperty ExtendedProperties).Subscriptions
          $Subscriptions = $Subscriptions.Split(',')
          if ($_ -in $Subscriptions) 
          {
            $true 
          }
          else 
          {
            throw "$_ is invalid."
          }
    })][string]$SubscritionID,
    [Validateset('Microsoft.RecoveryServices','Microsoft.StorageSync','Microsoft.Compute','Microsoft.Storage')][string[]]$Exclude,
    [switch]$checkexpireOn
  )

  begin {
    if ($checkexpireOn) 
    {
      $resourceGraphQuery = 'Resources | where todatetime(tags.expireOn) < now() | project id'
    }
    else 
    {
      $resourceGraphQuery = 'Resources | project id'
    }

    #create a custom exception to handle a Graph Resource error as a standard PowerShell exception
    class AzResourceGraphException : Exception {
      [string] $additionalData

      AzResourceGraphException($Message, $additionalData) : base($Message) 
      {
        $this.additionalData = $additionalData
      }
    }

    try
    {
      if ($S) 
      {
        $Connection = Connect-AzAccount -TenantId $TenantID -Subscription $S
      }
      else 
      {
        $Connection = Connect-AzAccount -TenantId $TenantID
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
        Write-Error -Message $_.Exception
        throw $_.Exception
      }
    }
    Write-Verbose -Message $Connection
  


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
      $index = 0..($array.Length -1) | Where-Object -FilterScript {
        $array[$_] -notin $Exclude
      }
      if($index -gt 0) 
      {
        $resourceID
      }
    }
  }

  process {

    ## Collect all expired resources
    #Limit search to one subscription by changing the PowerShell profile
    $PSDefaultParameterValues = @{
      'Search-AzGraph:Subscription' = $(Get-AzSubscription).ID
    }

    try 
    {
      if ($S) 
      {
        $expResources = Search-AzGraph -Query $resourceGraphQuery -ErrorVariable grapherror -ErrorAction SilentlyContinue -Subscription $S
      }
      else 
      {
        $expResources = Search-AzGraph -Query $resourceGraphQuery -ErrorVariable grapherror -ErrorAction SilentlyContinue
      }

      if ($null -ne $grapherror.Length) 
      {
        $errorJSON = $grapherror.ErrorDetails.Message | ConvertFrom-Json

        throw [AzResourceGraphException]::new($errorJSON.error.details.code, $errorJSON.error.details.message)
      }
    }
    catch [AzResourceGraphException] 
    {
      Write-Verbose -Message 'An error on KQL query'
      Write-Verbose -Message $_.Exception.message
      Write-Verbose -Message $_.Exception.additionalData
    }
    catch 
    {
      Write-Verbose -Message 'An error occurred in the script'
      Write-Verbose -Message $_.Exception.message
    }

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
          Remove-AzResource -ResourceId $res -Force
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
        $count = (Get-AzResource | Where-Object -FilterScript {
            $_.ResourceGroupName -match $RGname
        }).Count

        # now remove empty RGs
        if($count -eq 0)
        {
          Remove-AzResourceGroup -Name $RGname -Force
        }
      }
    }
  }
  end {
    $result
    Disconnect-AzAccount
  }
}
