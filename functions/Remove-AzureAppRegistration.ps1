Function Remove-AzureAppRegistration
{
  <#
      .Synopsis
      The cmdlet removes all app registrations.
    
      .Description
      The cmdlet removes all app registrations. It can exclude apps by the name.
      
     .PARAMETER TenantID
      This parameter is the actual tenant id. This is a mandatory parameter.

      .PARAMETER AppName
      This is a list of one or more application names to be deleted. If not specified, all applications will be deleted.
    
      .Example
      Remove-AzureAppRegistration -TenantID $TenantID
  #>

    [cmdletbinding()]
    Param(
    [Parameter(Mandatory)]
    [string]$TenantID,
    [string[]]$AppName
    )

    begin {
        #define the scope
        $scope = 'Application.ReadWrite.All,Directory.Read.All, Directory.ReadWrite.All'

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

        #get all apps
        $apps = Get-MgApplication -ConsistencyLevel eventual -Count appCount -All
        if($AppName) {
            $apps = $apps | Where-Object {$_.DisplayName -in $AppName}
            Write-PSFMessage -Level Verbose -Message "Will deltete only $($apps.Count) apps"
        }
        Write-PSFMessage -Level Verbose -Message "Will deltete $($appCount) apps"
    }

    process {
        if ($appCount) {
            foreach ($app in $apps) {
                try {
                    Remove-MgApplication -ApplicationId $app.Id
                    Write-PSFMessage -Level Verbose -Message "Deleted app registration: $($app.DisplayName)"
                }
                catch {
                    Write-PSFMessage -Level Error -Message "Error: $($_.Exception.Message)" -ModuleName 'AzureCleanup'
                }
            }
        }
    }
    end {
        Write-PSFMessage -Level Verbose -Message "... Deleted $($appCount) apps ..."   
        $null = Disconnect-Graph
    }
}