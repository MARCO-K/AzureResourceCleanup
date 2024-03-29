function Remove-AzureStorageAccount {
<#
   .SYNOPSIS
     Remove all StorageAccounts in a resource group
   
    .DESCRIPTION
    Remove all StorageAccounts in a resource group
  
    .PARAMETER TenantID
    This parameter is the actual tenant id. This is a mandatory parameter.
    
    .PARAMETER ResourceGroupName
    The name of the resource group
   
   .EXAMPLE
    Remove-AzStorageAccount -TenantID $tenant
   
   .EXAMPLE
    Remove-AzStorageAccount -TenantID $tenant -ResourceGroupName "MyResourceGroup" -Verbose
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
       Write-PSFMessage -Level Verbose -Message $Connection.SubscriptionName -ModuleName 'AzureResourceCleanup'
     }
     else
     {
       $context = Get-AzContext
       Write-PSFMessage -Level Verbose -Message "All StorageAccounts in context $($context.name) will be removed" -ModuleName 'AzureResourceCleanup'
     }

     # Get all RG names
     $RGs = Get-AzResourceGroup
     if($ResourceGroupName){
       Write-PSFMessage -Level Verbose -Message "Only StorageAccounts in resource group $ResourceGroupName will be removed" -ModuleName 'AzureResourceCleanup'
       $RGs = $RGs | Where-Object {$_.ResourceGroupName -eq $ResourceGroupName}
     }
     else {
      Write-PSFMessage -Level Verbose -Message "All StorageAccounts in ANY resource group will be removed" -ModuleName 'AzureResourceCleanup'
     }
     
   }

   process {
     foreach ($RG in $RGs)
     {
       Write-PSFMessage -Level Verbose -Message "Removing all StorageAccounts in resource group: $($RG.ResourceGroupName)" -ModuleName 'AzureResourceCleanup'
       $StorageAccounts = Get-AzStorageAccount -ResourceGroupName $RG.ResourceGroupName
       if($StorageAccounts) {
         foreach ($StorageAccount in $StorageAccounts)
         {
           Write-PSFMessage -Level Verbose -Message "Removing StorageAccount: $($StorageAccount.StorageAccountName)" -ModuleName 'AzureResourceCleanup'
           Remove-AzStorageAccount -ResourceGroupName $RG.ResourceGroupName -Name $StorageAccount.StorageAccountName -Force
         }
       }
     }
   }

   end {
     Write-PSFMessage -Level Verbose -Message "All StorageAccounts removed..." -ModuleName 'AzureResourceCleanup'
   }
}