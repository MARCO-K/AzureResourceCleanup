Function Get-AzureAllResource
{
  <#
    .Synopsis
    The cmdlet lists all Azure resources in any resource group.
    
    .Description
    The cmdlet lists all Azure resources in any resource group.
  
    .PARAMETER TenantID
    This parameter is the actual tenant id. The parmeter is mandatory.

    .PARAMETER SubscritionID
    This parameter is the actual subscription id.

    .PARAMETER Exclude
    This parameter can be used to exclude several resource types. Possible exclusions are: 'Microsoft.RecoveryServices','Microsoft.StorageSync','Microsoft.Compute','Microsoft.Storage'.

    .Parameter checkexpireOn
    This parameter can be used to check the ExpireOn tag.

    .Example
    Get-AzureAllresource -TenantID $TenantID -SubscritionID $SubscritionID -checkexpireOn

  #>

  [cmdletbinding()]
  Param(
    [Parameter(Mandatory)]
    [string]$TenantID,
    [string]$ResourceGroupName
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
        Write-PSFMessage -Level Error -Message $_.Exception -ModuleName 'AzResourceGraph'
        throw $_.Exception
      }
    }
    Write-PSFMessage -Level Verbose -Message $Connection.Context -ModuleName 'AzResourceGraph'
    
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
      $expResources =  
      if ($subscritionID) 
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
      Write-PSFMessage -Level Error -Message 'An error on KQL query' -ModuleName 'AzResourceGraph'
      Write-PSFMessage -Level Error -Message $_.Exception.message -ModuleName 'AzResourceGraph'
      Write-PSFMessage -Level Error -Message $_.Exception.additionalData -ModuleName 'AzResourceGraph'
    }
    catch 
    {
      Write-PSFMessage -Level Error -Message 'An error occurred in the script' -ModuleName 'AzResourceGraph'
      Write-PSFMessage -Level Error -Message $_.Exception.message -ModuleName 'AzResourceGraph'
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
          Get-AzResource -ResourceId $res
        }
        catch 
        {
          Write-PSFMessage -Level Error -Message $_.Exception -ModuleName 'AzResourceGraph'
        }
      }


    }
  }
  end {
    $result
    $null = Disconnect-AzAccount
  }
}