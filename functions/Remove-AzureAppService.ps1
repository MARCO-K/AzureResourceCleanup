Function Remove-AzureAppService
{
  <#
    .Synopsis
    The cmdlet removes all AzureAppServices and AppServicesPlans in any ressource groups.
    
    .Description
    The cmdlet removes all AzureAppServices in any ressource groups.
    
    .PARAMETER TenantID
    This parameter is the actual tenant id.
    
    .PARAMETER ResourceGroupName
    This parameter is the name of a resource group.

    .Example
    Remove-AzureAppService $tenant = ''

  #>

  [cmdletbinding()]
  Param(
    [Parameter(Mandatory)]
    [string]$TenantID,
    [string]$ResourceGroupName
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
    $RGs = Get-AzResourceGroup
    if($ResourceGroupName){
      Write-PSFMessage -Level Verbose -Message "Only AppServices in resource group $ResourceGroupName will be removed" -ModuleName 'AzureResourceCleanup'
      $RGs = $RGs | Where-Object {$_.ResourceGroupName -eq $ResourceGroupName}
    }
  }
  process{
    if ($RGs) {
      foreach($RG in $RGs){
        Write-PSFMessage -Level Verbose -Message "Removing AppServices in resource group $($RG.ResourceGroupName)" -ModuleName 'AzureResourceCleanup'
        $AppServices = Get-AzWebApp -ResourceGroupName $RG.ResourceGroupName
        if($AppServices){
          foreach($AppService in $AppServices){
            Write-PSFMessage -Level Verbose -Message "Removing AppService $($AppService.Name)" -ModuleName 'AzureResourceCleanup'
            try {
              Remove-AzWebApp -ResourceGroupName $RG.ResourceGroupName -Name $AppService.Name -Force
            }
            catch {
              $ErrorMessage = $_.Exception.Message
              Write-PSFMessage -Level Error -Message $ErrorMessage -ModuleName 'AzureResourceCleanup'
            }
          }
        }
        Write-PSFMessage -Level Verbose -Message "Removing AppServicesPlans in resource group $($RG.ResourceGroupName)" -ModuleName 'AzureResourceCleanup'
        $AppServicePlans = Get-AzAppServicePlan -ResourceGroupName $RG.ResourceGroupName
        if($AppServicePlans){
          foreach($AppServicePlan in $AppServicePlans){
            Write-PSFMessage -Level Verbose -Message "Removing AppServicePlan $($AppServicePlan.Name)" -ModuleName 'AzureResourceCleanup'
            try {
              Remove-AzAppServicePlan -ResourceGroupName $RG.ResourceGroupName -Name $AppServicePlan.Name -Force
            }
            catch {
              $ErrorMessage = $_.Exception.Message
              Write-PSFMessage -Level Error -Message $ErrorMessage -ModuleName 'AzureResourceCleanup'
            }
          }
        }
      }
    }
  }
  end {
    Write-PSFMessage -Level Verbose -Message '... Finished removing AppServices.' -ModuleName 'AzureResourceCleanup'
  }
}