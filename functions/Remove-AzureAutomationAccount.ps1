Function Remove-AzureAutomationAccount
{
  <#
      .Synopsis
      The cmdlet removes Automation Accounts form ALL Azure resources.
      
      .Description
      The cmdlet removes Automation Accounts form ALL Azure resources.
      It will also unlink workspaces.
      
      .PARAMETER TenantID
      This parameter is the actual tenant id.
  
      .Example
      Unlock-AzureLockedResource -TenantID $TenantID
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
      $Connection = 
      if ($subscritionID) {
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
        Write-PSFMessage -level Error -Message $_.Exception.Message -ModuleName 'AzureResourcecleanup'
        throw $_.Exception
      }
    }
    Write-PSFMessage -Level 'Verbose' -Message "Processing: $($Connection.Context.Subscription.Name)" -ModuleName 'AzureResourcecleanup'

    # Get all RG names
    $RGs = Get-AzResourceGroup
    if($ResourceGroupName){
      Write-PSFMessage -Level Verbose -Message "Only AppServices in resource group $ResourceGroupName will be removed" -ModuleName 'AzureResourceCleanup'
      $RGs = $RGs | Where-Object {$_.ResourceGroupName -eq $ResourceGroupName}
    }
    else {
      Write-PSFMessage -Level Verbose -Message "All StorageAccounts in ANY resource group will be removed" -ModuleName 'AzureResourceCleanup'
     }     
  }

  process {
    foreach($RG in $RGs) {
      # get all Automation Accounts
      $aa = Get-AzAutomationAccount -ResourceGroupName $RG.ResourceGroupName
      $ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $rg.ResourceGroupName
      if($ws)
        { $linked = Get-AzOperationalInsightsLinkedService -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $ws.Name }
      
      # unlink workspaces if linked
      if($aa -and $linked -and $ws) {
        Write-PSFMessage -Level Verbose -Message "Unlinking workspace $($ws.Name) from $($linked.Name)" -ModuleName 'AzureResourceCleanup'
        try {
          Remove-AzOperationalInsightsLinkedService -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $ws.Name -LinkedServiceName $linked.Name -
        }
        catch {
          Write-PSFMessage -Level Error -Message "Failed to unlink workspace $($ws.Name) from $($linked.Name)" -ModuleName 'AzureResourceCleanup'
        }
      }

      if($aa) {
        # remove Automation Accounts
        Write-PSFMessage -Level Verbose -Message "Removing Automation Account: $($aa.AutomationAccountName)" -ModuleName 'AzureResourceCleanup'
        try {
          Remove-AzAutomationAccount -ResourceGroupName $rg.ResourceGroupName -Name $aa.AutomationAccountName -Force
        }
        catch {
          Write-PSFMessage -Level Error -Message "Failed to remove Automation Account $($aa.AutomationAccountName)" -ModuleName 'AzureResourceCleanup'
        }      
      }
    }
  }
  end {
    Write-PSFMessage -Level Verbose -Message '... Finished removing utomation Accounts ...' -ModuleName 'AzureResourceCleanup'
    #disconnect from AZ account
    $null = Disconnect-AzAccount
  }
}