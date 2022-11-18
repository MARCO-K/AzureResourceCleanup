#Requires -Module @{ ModuleName = 'Az.RecoveryServices'; ModuleVersion = '6.1.0'}, @{ ModuleName = 'Az.Resources'; ModuleVersion = '6.4.0'}, @{ ModuleName = 'Az.Accounts'; ModuleVersion = '2.10.3'}

$tennant = '775fb56c-2847-4743-b9ff-51ffa2be3a64'
$ResourceGroupName = 'my-test-rg'
$Type = 'AzureVM' 
<#
    The acceptable values for this parameter are:
    AzureVM
    Windows
    AzureStorage
    AzureVMAppContainer
#>

# Get the connection
try
{
  $Connection = Connect-AzAccount -TenantId $tennant
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
    Write-Host -Message $_.Exception
    throw $_.Exception
  }
}
$Connection

# Prepare RG & RSV 
$RG = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -eq $ResourceGroupName }
$RSVs = Get-AzRecoveryServicesVault -ResourceGroupName $RG.ResourceGroupName

# Get all Vaults in RG
foreach($RSV in $RSVs) 
{ 
  $vault = Get-AzRecoveryServicesVault -ResourceGroupName $RG.ResourceGroupName -Name $RSV.Name
  $Container = Get-AzRecoveryServicesBackupContainer -VaultId $vault.ID -ContainerType $Type
  $BackupItem = Get-AzRecoveryServicesBackupItem -Container $Container -WorkloadType $Type -VaultId $vault.ID

  <#
    Set-AzRecoveryServicesVaultContext -Vault $vault
      Sets the vault context for Azure Site Recovery services.
      Warning: This cmdlet is being deprecated in a future breaking change release. There will be no replacement for it. Please use the -VaultId parameter in all Recovery Services commands going forward.
  #>

  Disable-AzRecoveryServicesBackupProtection -Item $BackupItem -Force -RemoveRecoveryPoints -VaultId $vault.ID -WhatIf
  Remove-AzRecoveryServicesVault -Vault $vault -WhatIf
}
