#Requires -Module @{ ModuleName = 'Az.Resources'; ModuleVersion = '6.4.0'}, @{ ModuleName = 'Az.Accounts'; ModuleVersion = '2.10.3'}

$tenant = '775fb56c-2847-4743-b9ff-51ffa2be3a64'

# Get the context
$context = Get-AzContext
if ($context.Tenant.Id -ne $tenant) {
# Get the connection
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
}
$Connection

## Collect all virtual machines
$VMs = Get-AzVM

if (!$VMs)
{
  Write-Host -Object 'No valid Azure virtual machine to delete'
  break
}
    
foreach($VM in $VMs) 
{
  # Get OS disk name from VM's properties
  $OSDiskName = $VM.StorageProfile.OsDisk.Name

  # Get OS disk delete option from VM's properties
  $OSDiskDeleteOption = $VM.StorageProfile.OsDisk.DeleteOption

  # Get data disk names from VM's properties
  $DataDiskName = $VM.StorageProfile.DataDisks.Name

  $DataDiskCount = $VM.StorageProfile.DataDisks.Count

  # If data disks are associated with the VM, list them and prompt the user whether to delete them or not
  if($DataDiskCount -gt 0)
  {
    # Get data disk delete option from VM's properties
    $DataDiskDeleteOption = $VM.StorageProfile.DataDisks.DeleteOption[0]
  }


  # Get network interface name from VM's properties
  $NICName = $VM.NetworkProfile.NetworkInterfaces.Id.Split('/')[-1]

  # Get network interface delete option from VM's properties
  $NIDeleteOption = $VM.NetworkProfile.NetworkInterfaces.DeleteOption
 
  $NIC = Get-AzNetworkInterface -Name $NICName
 
  # Get public IP name from network interface properties
  $PublicIPName = $NIC.IpConfigurations.PublicIpAddress.Id.Split('/')[-1]

  # Retrieve public IP properties
  $PublicIP = Get-AzPublicIpAddress -ResourceGroupName $VM.ResourceGroupName -Name $PublicIPName

  if($PublicIP)
  {
    # Get network interface delete option from VM's properties
    $PublicIPDeleteOption = $VM.NetworkProfile.NetworkInterfaces.DeleteOption
  }


  # Delete Azure virtual machine
  try 
  {
    Stop-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
    Remove-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
  }
  catch 
  {
    Write-Error -Message $_.Exception
  }


  # If OS disk delete option is detach, delete the OS disk
  if ($OSDiskDeleteOption -eq 'Detach') 
  {
    try 
    {
      # Delete OS disk
      Remove-AzDisk -ResourceGroupName $VM.ResourceGroupName -DiskName $OSDiskName
    }
    catch 
    {
      Write-Error -Message $_.Exception
    }
  }

  # If data disks exist, run deletion conditionals
  if ($DataDiskCount -gt 0)
  {
    # If  data disk delete option is  detach, delete the data disks
    if ($DataDiskDeleteOption -eq 'Detach') 
    {
      try 
      {
        # Delete each data disk found from VM properties - $VM.StorageProfile.DataDisks.Name
        foreach ($Disk in $DataDiskName) 
        {
          Remove-AzDisk -ResourceGroupName $VM.ResourceGroupName -DiskName $Disk
        }
      }
      catch 
      {
        Write-Error -Message $_.Exception
      }
    }
  }

  # If network interface delete option is detach, delete the network interface
  if ($NIDeleteOption -eq 'Detach') 
  {
    try 
    {
      # Delete Network Interface
      Remove-AzNetworkInterface -Name $NIC.Name -ResourceGroupName $VM.ResourceGroupName
    }
    catch 
    {
      Write-Error -Message $_.Exception
    }
  }

  # The public IP delete option is typically the same as the network interface delete option - therefore skipping else case
  if ($PublicIPDeleteOption -eq 'Detach') 
  {
    try 
    {
      # Delete public IP address
      Remove-AzPublicIpAddress -Name $PublicIP.Name -ResourceGroupName $VM.ResourceGroupName
    }
    catch 
    {
      Write-Error -Message $_.Exception
    }
  }
}
