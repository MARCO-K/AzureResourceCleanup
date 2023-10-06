Function Add-AzureExpiredTag
{
  <#
      .Synopsis
      The cmdlet adds an expiredOn tag to all ressources.
      .Description
      The cmdlet removes Azure custom policies incl. all assignments and definitions.
      .PARAMETER TenantID
      This parameter is the actual tenant id.
      .Example
      PS C:\> Remove-AzurePolicy $tenant = ''

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
    $context = Get-AzContext
    if ($context.Tenant.Id -ne $TenantID) 
    {
      # Get the connection

      try
      {
        $Connection = Connect-AzAccount -TenantId $TenantID
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
    }
    $date = ([datetime]::ParseExact($expireOn,'MM/dd/yyyy',$null))
    
  }
  Process {
    # Get all RG names
    $RGs = (Get-AzResourceGroup).ResourceGroupName

    $result = 
    foreach($RG in $RGs) 
    {
      # Set Tag for RG
      Set-AzResourceGroup -ResourceId (Get-AzResourceGroup -Name $RG).ResourceId -Tag @{
        expireOn = $date
      }

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
          Set-AzResource -Tag $tags -ResourceId $r.ResourceId -Force
        }
        else
        {
          Set-AzResource -Tag $group.Tags -ResourceId $r.ResourceId -Force
        }
      }
    }
  }

  end {
    $result
    Disconnect-AzAccount
  }
}
