Function Remove-AzureRecoveryService 
{
  <#
      .Synopsis
      The cmdlet removes Azure Recovery Service.
      .Description
      The cmdlet removes Azure RecoveryService incl. all backup items and RecoveryServicesVault
      .PARAMETER TenantId
      This parameter is the actual tenant id.
      .PARAMETER ContainerType
      This parameter is the type of the container. Valid values are AzureVM, Windows, AzureStorage, AzureVMAppContainer.
      .Example
      Remove-AzureRecoveryService -TenantId 'xxx-xxx-xx-xxxx-xxx' -ContainerType 'AzureVM'

  #>


  [cmdletbinding()]
  Param(    
    [Parameter(Mandatory)][string]$TenantId,
    [Parameter(Mandatory)][Validateset('AzureVM','Windows','AzureStorage','AzureVMAppContainer')][string]$ContainerType
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
      Write-PSFMessage -Level Verbose -Message "All vault in context $($context.name) will be removed" -ModuleName 'AzureResourceCleanup'
    }
  }

  process {
    # Get all Vaults
    $vaults = Get-AzRecoveryServicesVault

    ## only 1 vault exists
    if ($vaults.Count -eq 1) 
    {
      $vault = $vaults

      ## set context by selecting the container
      $container = Get-AzRecoveryServicesBackupContainer -VaultId $vault.ID -ContainerType $ContainerType

      ## Disable soft delete for the Azure Backup Recovery Services vault
      $vaultProp = Get-AzRecoveryServicesVaultProperty -VaultId $vault.ID
      if ($vaultProp.SoftDeleteFeatureState -eq 'Enabled') 
      {
        $prop_res = Set-AzRecoveryServicesVaultProperty -VaultId $vault.ID -SoftDeleteFeatureState Disable -Confirm:$false -ErrorAction SilentlyContinue -ErrorVariable err
        if ($err -ne $null) 
        {
          Write-PSFMessage -Level Error -Message "Error while disabling soft delete for the Azure Backup Recovery Services vault: $err" -ModuleName 'AzureResourceCleanup'
        }
        else 
        {
          Write-PSFMessage -Level Verbose -Message $prop_res -ModuleName 'AzureResourceCleanup'
        }
      }

      ## Check if there are backup items in a soft-deleted state and reverse the delete operation
      $BackupItems = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM -VaultId $vault.ID | Where-Object -FilterScript {
        $_.DeleteState -eq 'ToBeDeleted'
      }

      if ($BackupItems.Count -gt 0) 
      {
        foreach($BackupItem in $BackupItems)
        {
          try 
          {
            Undo-AzRecoveryServicesBackupItemDeletion -Item $BackupItem -VaultId $vault.ID -Force 
            Write-PSFMessage -Level Verbose -Message "Soft-deleted state for $($BackupItem.Name) in vault $($vault.Name) reversed" -ModuleName 'AzureResourceCleanup'
          } catch 
          {
            Write-PSFMessage -Level Warning -Message "Failed to reverse soft-deleted state for $($BackupItem.Name) in vault $($vault.Name)" -ModuleName 'AzureResourceCleanup'
          }
        }
      }

      ## Stop protection and delete data for all backup-protected items
      $BackupItems = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM -VaultId $vault.ID | Where-Object -FilterScript {
        $_.DeleteState -eq 'NotDeleted'
      }

      if ($BackupItems.Count -gt 0) 
      {
        foreach($BackupItem in  $BackupItems)
        {  
          try 
          {
            Disable-AzRecoveryServicesBackupProtection -Item $BackupItem -Force -RemoveRecoveryPoints -VaultId $vault.ID 
            Write-PSFMessage -Level Verbose -Message "Disabled backup for $($BackupItem.Name) in vault $($vault.Name)" -ModuleName 'AzureResourceCleanup'
          } catch 
          {
            Write-PSFMessage -Level Warning -Message "Failed to disable backup for $($BackupItem.Name) in vault $($vault.Name)" -ModuleName 'AzureResourceCleanup'
          }
        }
      }

      Write-PSFMessage -Level Verbose -Message "All backup items for vault $($vault.Name) removed" -ModuleName 'AzureResourceCleanup'
    
      # Check if the vault is empty and then delete it
      $BackupItems = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM -VaultId $vault.ID
      if ($BackupItems.Count -eq 0) 
      {
        Write-PSFMessage -Level Verbose -Message "The vault $($vault.Name) is empty and will be deleted" -ModuleName 'AzureResourceCleanup'
        Remove-AzRecoveryServicesVault -Vault $vault -Confirm:$false
        Write-PSFMessage -Level Verbose -Message "The vault $($vault.Name) has been deleted" -ModuleName 'AzureResourceCleanup'
      }
      else 
      {
        $ErrorMessage = "The vault $($vault.Name) contains $($BackupItems.Count) items"
        Write-PSFMessage -Level Error -Message $ErrorMessage -ModuleName 'AzureResourceCleanup'
        throw $ErrorMessage
      }
    }
    ## more than 1 vault exists
    elseif ($vaults.Count -gt 1) 
    {
      foreach($vault in $vaults) 
      {
        ## set context by selecting the container
        $container = Get-AzRecoveryServicesBackupContainer -VaultId $vault.ID -ContainerType $ContainerType
        
        ## Disable soft delete for the Azure Backup Recovery Services vault
        $vaultProp = Get-AzRecoveryServicesVaultProperty -VaultId $vault.ID
        if ($vaultProp.SoftDeleteFeatureState -eq 'Enabled') 
        {
          $prop_res = Set-AzRecoveryServicesVaultProperty -VaultId $vault.ID -SoftDeleteFeatureState Disable -Confirm:$false -ErrorAction SilentlyContinue -ErrorVariable err
          if ($err -ne $null) 
          {
            Write-PSFMessage -Level Error -Message "Error while disabling soft delete for the Azure Backup Recovery Services vault: $err" -ModuleName 'AzureResourceCleanup'
          }
          else 
          {
            Write-PSFMessage -Level Verbose -Message $prop_res -ModuleName 'AzureResourceCleanup'
          }
        }

        ## Check if there are backup items in a soft-deleted state and reverse the delete operation
        $BackupItems = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM -VaultId $vault.ID | Where-Object -FilterScript {
          $_.DeleteState -eq 'ToBeDeleted'
        }

        if ($BackupItems.Count -gt 0) 
        {
          foreach($BackupItem in $BackupItems)
          {
            try 
            {
              Undo-AzRecoveryServicesBackupItemDeletion -Item $BackupItem -VaultId $vault.ID -Force 
              Write-PSFMessage -Level Verbose -Message "Soft-deleted state for $($BackupItem.Name) in vault $($vault.Name) reversed" -ModuleName 'AzureResourceCleanup'
            } catch 
            {
              Write-PSFMessage -Level Warning -Message "Failed to reverse soft-deleted state for $($BackupItem.Name) in vault $($vault.Name)" -ModuleName 'AzureResourceCleanup'
            }
          }
        }

        ## Stop protection and delete data for all backup-protected items
        $BackupItems = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM -VaultId $vault.ID | Where-Object -FilterScript {
          $_.DeleteState -eq 'NotDeleted'
        }

        if ($BackupItems.Count -gt 0) 
        {
          foreach($BackupItem in  $BackupItems)
          {  
            try 
            {
              Disable-AzRecoveryServicesBackupProtection -Item $BackupItem -Force -RemoveRecoveryPoints -VaultId $vault.ID 
              Write-PSFMessage -Level Verbose -Message "Disabled backup for $($BackupItem.Name) in vault $($vault.Name)" -ModuleName 'AzureResourceCleanup'
            } catch 
            {
              Write-PSFMessage -Level Warning -Message "Failed to disable backup for $($BackupItem.Name) in vault $($vault.Name)" -ModuleName 'AzureResourceCleanup'
            }
          }
        }
        Write-PSFMessage -Level Verbose -Message "All backup items for vault $($vault.Name) removed" -ModuleName 'AzureResourceCleanup'

        # Check if the vault is empty and then delete it
        $BackupItems = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM -VaultId $vault.ID
        if ($BackupItems.Count -eq 0) 
        {
          Write-PSFMessage -Level Verbose -Message "The vault $($vault.Name) is empty and will be deleted" -ModuleName 'AzureResourceCleanup'
          Remove-AzRecoveryServicesVault -Vault $vault -Confirm:$false
          Write-PSFMessage -Level Verbose -Message "The vault $($vault.Name) has been deleted" -ModuleName 'AzureResourceCleanup'
        }
        else 
        {
          $ErrorMessage = "The vault $($vault.Name) contains $($BackupItems.Count) items"
          Write-PSFMessage -Level Error -Message $ErrorMessage -ModuleName 'AzureResourceCleanup'
          throw $ErrorMessage
        }
      }
    }

    else 
    {
      $ErrorMessage = 'No vault found.'
      throw $ErrorMessage
    }
  }  
  end {
    Write-PSFMessage -Level Verbose -Message "All vaults in context $($context.Name) has been deleted" -ModuleName 'AzureResourceCleanup'
    Disconnect-AzAccount -Scope Process
  }
} 
