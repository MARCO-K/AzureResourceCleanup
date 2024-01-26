Function Remove-AzureLogAnalyticsWorkspace
{
  <#
      .Synopsis
      The cmdlet removes LogAnalyticsWorkspaces form Azure resource groups.
      
      .Description
      The cmdlet removes LogAnalyticsWorkspaces form Azure resource groups.
      It will permanently delete the workspaces.
      
      .PARAMETER TenantID
      This parameter is the actual tenant id.
  
      .Example
      Remove-AzureLogAnalyticsWorkspace -TenantID $TenantID
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
        foreach ($RG in $RGs) {
            Write-PSFMessage -Level Verbose -Message "Processing resource group $($RG.ResourceGroupName)" -ModuleName 'AzureResourceCleanup'
            $LogAnalyticsWorkspaces = Get-AzOperationalInsightsWorkspace -ResourceGroupName $RG.ResourceGroupName
            if ($LogAnalyticsWorkspaces) {
                foreach ($LogAnalyticsWorkspace in $LogAnalyticsWorkspaces) {
                Write-PSFMessage -Level Verbose -Message "Removing LogAnalyticsWorkspace $($LogAnalyticsWorkspace.Name)" -ModuleName 'AzureResourceCleanup'
                Remove-AzOperationalInsightsWorkspace -ResourceGroupName $rg.ResourceGroupName -Name $LogAnalyticsWorkspace.Name -ForceDelete -Confirm:$False
                }
            }
        }
    }

    end {
    Write-PSFMessage -Level 'Verbose' -Message "Disconnecting from Azure" -ModuleName 'AzureResourcecleanup'
    $null = Disconnect-AzAccount -Scope Process
    }
}