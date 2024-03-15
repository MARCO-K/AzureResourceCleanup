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

    .PARAMETER keepAlive
    This parameter can be used to keep the connection alive.

    .Example
     Add-AzureExpiredTag $tenant = ''

  #>

  [cmdletbinding()]
  Param(
    [Parameter(Mandatory)]
    [string]$TenantID,
    [parameter(Mandatory,Helpmessage = 'Input format: yyyy/mm/dd')][ValidateScript(`
        {
          ([datetime]::ParseExact($_,'yyyy/mm/dd',[cultureinfo]::CreateSpecificCulture('en-US')) -le (Get-Date)) 
    })]$expireOn,
    [Parameter(Mandatory=$false)][switch]$keepAlive
  )

  begin {
    # check for existing connection to Azure
    $context = Get-AzContext -ListAvailable
    $tag = @{ 'expireOn' = $expireOn }
    
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
      Write-PSFMessage -Level Verbose -Message "All tags in context $($context.name) will be updated" -ModuleName 'AzureResourceCleanup'
    }

    # Get all RG names
    $RGs = Get-AzResourceGroup

  }

  Process {
    if($RGs) { 
      foreach($RG in $RGs) 
      {
        $group = Get-AzResourceGroup -Name $RG.ResourceGroupName
      
        # Get all resources in RG and add TAG
        $resources = Get-AzResource -ResourceGroupName $group.ResourceGroupName

        if($resources){ 
          foreach ($r in $resources) 
          {
              # check if it is already tagged
              $tags = (Get-AzResource -ResourceId $r.ResourceId).Tags
              if ($tags) 
              {
                  $tags.Add( 'expireOn', $expireOn )
              
                write-PSFMessage -Level Verbose -Message "Tagging $($r.Name) with $($tags)" -ModuleName 'AzureResourceCleanup' 
                $null = Set-AzResource -ResourceId $r.ResourceId -Tag $tags -force
              }
              else
              {
                write-PSFMessage -Level Verbose -Message "Tagging $($r.Name)" -ModuleName 'AzureResourceCleanup'  
                $null = Set-AzResource -ResourceId $r.ResourceId -Tag $tag -force
              }
          }
        }
        # Set Tag for RG
       write-PSFMessage -Level Verbose -Message "Tagging $($RG.ResourceGroupName) with $($tag)" -ModuleName 'AzureResourceCleanup'
       $null = Set-AzResourceGroup -Id $RG.ResourceId -Tag $tag
      }
    }
  }
end {
    Write-PSFMessage -Level Verbose -Message "All resource groups and  in context $($context.Name) has have been tagged" -ModuleName 'AzureResourceCleanup'
    if(-not $keepAlive) {
      $null = Disconnect-AzAccount
    }
  }
}