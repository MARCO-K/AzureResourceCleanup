Function Remove-AzureSynchService 
{
  <#
      .Synopsis
      The cmdlet removes Azure SynchService.
      .Description
      The cmdlet removes Azure SynchService incl.clound and server endpoints.
      .PARAMETER tenant
      This parameter is the actual tenant id.
      .Example
      PS C:\> Clean-AzureSynchService $tenant = ''

  #>


  [cmdletbinding()]
  Param(    [Parameter(Mandatory)]
  [string]$tenant)

  begin {
    try
    {
$Connection = Connect-AzAccount -TenantId $tenant
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
    $syncService = Get-AzStorageSyncService
    $synGroup = Get-AzStorageSyncGroup -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName
    $syncServers = Get-AzStorageSyncServer -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName
    $result = 
    foreach($syncServer in $syncServers) 
    {
      # Lists all server endpoints
      $syncServerEPs = Get-AzStorageSyncServerEndpoint -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName -SyncGroupName $synGroup.SyncGroupName
  
      foreach($syncServerEP in $syncServerEPs) 
      {
Remove-AzStorageSyncServerEndpoint -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName -SyncGroupName $synGroup.SyncGroupName -Name $syncServerEP.ServerName -Force -PassThru
}
  
      Unregister-AzStorageSyncServer -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName -ServerId $syncServer.ServerId -Force
    }
    $syncCEP = Get-AzStorageSyncCloudEndpoint -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName -SyncGroupName $synGroup.SyncGroupName
    Remove-AzStorageSyncCloudEndpoint -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName -SyncGroupName $synGroup.SyncGroupName -Name $syncCEP.CloudEndpointName -Force -PassThru
    Remove-AzStorageSyncGroup -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName -SyncGroupName $synGroup.SyncGroupName -PassThru -Force
    Remove-AzStorageSyncService -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName -PassThru -Force
  }
  end {
    $result
  }
} 
