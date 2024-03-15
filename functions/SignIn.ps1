Function SignIn {
    param ([Parameter(Mandatory)]$Connection)

    try { 
        $ctx = Get-AzContext -ListAvailable -DefaultProfile $Connection.Context
    }
    catch { 
        Write-PSFMessage -Level Error -Message 'cannot create context'
    }

    if ($ctx) {
        Write-PSFMessage -Level Verbose -Message 'Already signed in to Azure.'
        $true
    }
    else {
        Write-PSFMessage -Level Verbose -Message 'Not signed in to Azure.'
        $false
    }  
}