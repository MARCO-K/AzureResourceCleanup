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

    .PARAMETER AccessToken
    This parameter is the actual access token. 
    .PARAMETER AccountID
    This parameter is the actual account id. If an AccessToken is provided this parmeter is mandatory.

    
    .PARAMETER Exclude
    This parameter can be used to exclude several resource types. Possible exclusions are: 'Microsoft.RecoveryServices','Microsoft.StorageSync','Microsoft.Compute','Microsoft.Storage'.

    .Parameter checkexpireOn
    This parameter can be used to check the ExpireOn tag.

    .PARAMETER keepAlive
    This parameter can be used to keep the connection alive.

    .Example
    Get-AzureAllresource -TenantID $TenantID -SubscritionID $SubscritionID -checkexpireOn

  #>

  [cmdletbinding()]
  Param(
    [Parameter(Mandatory=$false)][string]$TenantID,
    [Parameter(Mandatory=$false)][string]$subscritionID,
    [Parameter(Mandatory=$false,ParameterSetName="TokenObj")]$AccessToken = $null,
    [Parameter(Mandatory,ParameterSetName="TokenObj")][string]$AccountID,
    [Parameter(Mandatory=$false,ParameterSetName="ConnObj")]$Connection = $null,
    [Parameter(Mandatory=$false)][string[]]$Exclude = @('Microsoft.RecoveryServices','Microsoft.StorageSync','Microsoft.Compute','Microsoft.Storage'),
    [Parameter(Mandatory=$false)][switch]$CheckExpireOn,
    [Parameter(Mandatory=$false)][switch]$keepAlive
  )

  begin {
    if(-not $Connection) {
      #connect to AZ account
      try
      {
        if(-not $AccessToken){ 
          $Connection = if ($subscritionID) {
            Connect-AzAccount -TenantId $TenantID -Subscription $subscritionID
          }
          else  {
            ### needs some more testing
            Connect-AzAccount -TenantId $TenantID -AccessToken $AccessToken.access_token -AccountId $AccountID
          }
        }
        else {
          $Connection = Connect-AzAccount -AccessToken $AccessToken -AccountId $AccountID -TenantId $TenantID
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
    }
    else {
      if(SignIn $connection) {
        Write-PSFMessage -Level Verbose -Message "... Already connected to: $($Connection.Context.Subscription)" -ModuleName 'AzResourceGraph'
      }
      else {
        Write-PSFMessage -Level Error -Message '... Connection not found.' -ModuleName 'AzResourceGraph'
        throw '... Connection not found.'
      }
    }
    
    #check if expireOn tag should be used
    $resourceGraphQuery = if ($CheckExpireOn) {
      Write-PSFMessage -Level Verbose -Message '... Checking only for expired resources' -ModuleName 'AzResourceGraph'
      'Resources | where todatetime(tags.expireOn) < now()'
    } else {
      Write-PSFMessage -Level Verbose -Message '... Checking all resources' -ModuleName 'AzResourceGraph'
      'Resources'
    }
    
    # Get all locked resources
    $lockedResources = Get-AzResourceLock -DefaultProfile $Connection.Context -ErrorAction SilentlyContinue
    
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
        if ((($res.type).split('/')[0] -inotin $Exclude ) -and ($res.Name -inotin $lockedResources.ResourceName) ) 
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
          $resource = Get-AzResource -ResourceId $res
          [PSCustomObject]@{         
            Name = $resource.Name
            ResourceId = $resource.ResourceId
            ResourceGroupName = $resource.ResourceGroupName
            ResourceType = $resource.ResourceType
            Location = $resource.Location
            Tags = $resource.Tags
          }
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
    if(-not $keepAlive) {
          $null = Disconnect-AzAccount
    }
}
}