Function Remove-AzureAllRoleMember
{
  <#
    .Synopsis
    The cmdlet removes all directory role members.
    
    .Description
    The cmdlet removes all directory role members.
    It eexcludes all members of the Global Administrator role.
    
    .PARAMETER TenantID
    This parameter is the actual tenant id.

    .Example
     Remove-AzureAllRoleMember $tenant = ''

  #>

  [cmdletbinding()]
  Param(
    [Parameter(Mandatory)]
    [string]$TenantID
  )

  begin {
    # check for existing connection to Azure
    $context = Get-MgContext
    
    ## if no connection exists then try to connect
    if ($context.count -eq 0) 
    {
      try
      {
        $Connection = Connect-MgGraph -TenantId $tenantid -NoWelcome -Scopes "RoleManagement.ReadWrite.Directory"
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
    }
    else 
    {
      Write-PSFMessage -Level Verbose -Message "All directory role memberships will be removed" -ModuleName 'AzureResourceCleanup'
    }

    # Get all roles except 'Global Administrator'
    $roles = Get-MgDirectoryRole -All | Where-Object { $_.DisplayName -ne 'Global Administrator'}


  }

  process{
    if($roles) { 
        foreach ($role in $roles) {
    
            $userList = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
            if($userList) { 
                foreach($user in $userList) {
                    try {
                        Remove-MgDirectoryRoleMemberByRef -DirectoryRoleId $role.Id -DirectoryObjectId $user.Id
                        Write-PSFMessage -Level Verbose -Message "Removed $((Get-MgUser -UserId $user.Id).DisplayName) from $($role.DisplayName)"
                    }
                    catch {
                        write-PSFMessage -Level Error -Message $_.Exception.Message
                    }
                }
            }
        }
    }
  }
  end{
    $null = Disconnect-MgGraph
  }
}