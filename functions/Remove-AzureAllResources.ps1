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
    })][string]$subscritionID,
    [Validateset('Microsoft.RecoveryServices','Microsoft.StorageSync','Microsoft.Compute','Microsoft.Storage')][string[]]$Exclude,
    [switch]$checkexpireOn
  )

  begin {
    #connect to AZ account
    try
    {
      $Connection = if ($subscritionID) {
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
        Write-Error -Message $_.Exception
        throw $_.Exception
      }
    }
    Write-Verbose -Message $Connection
    
        #check if expireOn tag should be used
    $resourceGraphQuery = if ($CheckExpireOn) {
      'Resources | where todatetime(tags.expireOn) < now()'
    } else {
      'Resources'
    }
    
    # Get all locked resources
    $lockedResources = Get-AzResourceLock | Select-Object -ExpandProperty ResourceName
    
    #create a custom exception to handle a Graph Resource error as a standard PowerShell exception
    class AzResourceGraphException : Exception {
      [string] $additionalData
      AzResourceGraphException($Message, $additionalData) : base($Message) 
      {
        $this.additionalData = $additionalData
      }
    }
  }
  
  process {

    ## Collect all expired resources
    try 
    {
      $expResources =  if ($subscritionID) 
      {
        Search-AzGraph -Query $resourceGraphQuery -ErrorVariable grapherror -ErrorAction SilentlyContinue -Subscription $subscritionID
      }
      else 
      {
        Search-AzGraph -Query $resourceGraphQuery -ErrorVariable grapherror -ErrorAction SilentlyContinue
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



    #exclude locked and excluded resources
    $resources = 
    foreach($res in $expResources) {
        if ((($res.type).split('/')[0] -inotin $Exclude ) -and ($res.Name -inotin $lockedResources) ) 
        { $res }
    }
    

    if($resources.Count -gt 0) 
    { 
      $result = 
      foreach ($res in $resources.id) 
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
 
      $result +=
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
    $null = Disconnect-AzAccount
  }
}
