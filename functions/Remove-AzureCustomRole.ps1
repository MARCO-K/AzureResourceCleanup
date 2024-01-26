Function Remove-AzureCustomRole
{
  <#
      .Synopsis
      The cmdlet removes Entra custom directory roles.

      .Description
      The cmdlet removes Entra custom directory roles. It can exclude roles by name .

     .PARAMETER TenantID
      This parameter is the actual tenant id. This is a mandatory parameter.

      .PARAMETER RoleName
      This is a list of one or more role names to be deleted. If not specified, all custom roles will be deleted.

      .Example
      Remove-AzureCustomRole -TenantID $TenantID
  #>

    [cmdletbinding()]
    Param(
    [Parameter(Mandatory)]
    [string]$TenantID,
    [string[]]$RoleName
    )

    begin {
        #define the scope
        $scope = 'RoleManagement.ReadWrite.Directory'

        #connect to AZ account
        try
        {
        $connection = Connect-MgGraph -Scopes $scope -TenantId $tenantID -NoWelcome
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
            Write-PSFMessage -Level Error -Message $_.Exception.Message -ModuleName 'AzureResourceCleanup'
            throw $_.Exception
        }
        }

        #get all custom roles
        $roles = Get-MgRoleManagementDirectoryRoleDefinition -Filter "IsBuiltIn eq false" -CountVariable roleCount -All

        if($roleCount) {
            $roles = $roles | Where-Object {$_.DisplayName -in $RoleName}
            Write-PSFMessage -Level Verbose -Message "Will deltete only $($roles.Count) apps"
        }
        Write-PSFMessage -Level Verbose -Message "Will deltete $($roles.Count) roles"
    }

    process {
        if ($roles.Count) {
            foreach ($role in $roles) {
                try {
                    Remove-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $role.Id
                    Write-PSFMessage -Level Verbose -Message "Deleted custom role: $($role.DisplayName)"
                }
                catch {
                    Write-PSFMessage -Level Error -Message "Error: $($_.Exception.Message)" -ModuleName 'AzureCleanup'
                }
            }
        }
    }
    end {
        Write-PSFMessage -Level Verbose -Message "... Deleted $($roleCount) roles ..."
        $null = Disconnect-MgGraph
    }
}