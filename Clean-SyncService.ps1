#Requires -Module @{ ModuleName = 'Az.StorageSync'; ModuleVersion = '1.7.0'}, @{ ModuleName = 'Az.Resources'; ModuleVersion = '6.4.0'}, @{ ModuleName = 'Az.Accounts'; ModuleVersion = '2.10.3'}

$tennant = '775fb56c-2847-4743-b9ff-51ffa2be3a64'

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
    Write-Error -Message $_.Exception
    throw $_.Exception
  }
}
$Connection

##Azure part
# Collect basic infos
$syncService = Get-AzStorageSyncService
$synGroup = Get-AzStorageSyncGroup -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName

# Lists all registered server within a given sync group
$syncServers = Get-AzStorageSyncServer -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName

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

# now remove the cloud endpoint
$syncCEP = Get-AzStorageSyncCloudEndpoint -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName -SyncGroupName $synGroup.SyncGroupName
Remove-AzStorageSyncCloudEndpoint -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName -SyncGroupName $synGroup.SyncGroupName -Name $syncCEP.CloudEndpointName -Force -PassThru

# finally remove SyncGroup & Service
Remove-AzStorageSyncGroup -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName -SyncGroupName $synGroup.SyncGroupName -PassThru -Force
Remove-AzStorageSyncService -ResourceGroupName $syncService.ResourceGroupName -StorageSyncServiceName $syncService.StorageSyncServiceName -PassThru -Force