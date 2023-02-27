Function Remove-AzureRecoveryService 
{
  <#
      .Synopsis
      The cmdlet removes Azure Recovery Service.
      .Description
      The cmdlet removes Azure RecoveryService incl. all backup items and RecoveryServicesVault
      .PARAMETER tenant
      This parameter is the actual tenant id.
      .Example
      PS C:\> Remove-AzureRecoveryService $tenant = ''

  #>


  [cmdletbinding()]
  Param(    
    [Parameter(Mandatory)][string]$TenantId,
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][Validateset('AzureVM','Windows','AzureStorage','AzureVMAppContainer')][string]$Type
  )

  begin {
    try
    {
      $Connection = Connect-AzAccount -TenantId $TenantId
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

  process {
    # Prepare RG & RSV 
    $RG = Get-AzResourceGroup | Where-Object -FilterScript {
      $_.ResourceGroupName -eq $ResourceGroupName 
    }
    $RSVs = Get-AzRecoveryServicesVault -ResourceGroupName $RG.ResourceGroupName

    # Get all Vaults in RG
    $result = 
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
  }
  end {
    $result
  }
} 
