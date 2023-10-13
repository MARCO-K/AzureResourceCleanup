Function Add-AzureExpiredTag
{
  <#
    .Synopsis
    The cmdlet adds an expiredOn tag to all ressources.
    
    .Description
    The cmdlet adds an expiredOn tag to all ressourcesand resource groups. 
    The tag is set to the date specified in the parameter expireOn.
    
    .PARAMETER TenantID
    This parameter is the actual tenant id.
    
    .PARAMETER expireOn
    This parameter is the date when the ressources will be deleted.

    .Example
     Add-AzureExpiredTag $tenant = ''

  #>

  [cmdletbinding()]
  Param(
    [Parameter(Mandatory)]
    [string]$TenantID,
    [parameter(Mandatory,Helpmessage = 'Input format: yyyy-mm-dd')][ValidateScript(`
        {
          ([datetime]::ParseExact($_,'yyyy-mm-dd',[cultureinfo]::CreateSpecificCulture('en-US')) -le (Get-Date)) 
    })]$expireOn
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
      $group = Get-AzResourceGroup -Name $RG
    
      # Get all resources in RG and add TAG
      $resources = Get-AzResource -ResourceGroupName $group.ResourceGroupName
      foreach ($r in $resources) 
      {
        # check if it is already tagged
        $tags = (Get-AzResource -ResourceId $r.ResourceId).Tags
        if ($tags) 
        {
          foreach ($key in $group.Tags.Keys) 
          {
            if (-not($tags.ContainsKey($key))) 
            {
              $tags.Add($key, $group.Tags.$key)
            }
          }
          Write-PSFMessage -Level Verbose -Message "Tagging $($r.Name) with $($group.Tags)" -ModuleName 'AzureResourceCleanup'
          Set-AzResource -Tag $tags -ResourceId $r.ResourceId -Force
        }
        else
        {
          write-PSFMessage -Level Verbose -Message "Tagging $($r.Name) with $($group.Tags)" -ModuleName 'AzureResourceCleanup'
          Set-AzResource -Tag $group.Tags -ResourceId $r.ResourceId -Force
        }
      }

      # Set Tag for RG
      write-PSFMessage -Level Verbose -Message "Tagging $($group.ResourceGroupName) with $($group.Tags)" -ModuleName 'AzureResourceCleanup'
      Set-AzResourceGroup -ResourceId (Get-AzResourceGroup -Name $RG).ResourceId -Tag @{
        expireOn = $date
      }
    }
  }

  end {
    Write-PSFMessage -Level Verbose -Message "All resource groups and  in context $($context.Name) has have been tagged" -ModuleName 'AzureResourceCleanup'
    $null = Disconnect-AzAccount -Scope Process
  }
}
