function Get-AzureAuthToken{
    <#
    .SYNOPSIS
        Authenticate and store tokens in the global $tokens variable as well as the tenant ID in $tenantid. 

    .DESCRIPTION      
        Authenticate and store tokens in the global $tokens variable as well as the tenant ID in $tenantid.
    .PARAMETER Credential
        Provide a Credential for authentication.

    .PARAMETER ClientID
        Provide a ClientID to use with the Custom client option.

    .PARAMETER Resource
        Provide a resource to authenticate to such as https://graph.microsoft.com/

    .EXAMPLE
        
        Get-AzureAuthToken -Credential $cred -Client MSGraph -Resource https://graph.microsoft.com
        
     #>
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$false, ParameterSetName = 'Credential')]
    [pscredential]$credential,
    [Parameter(Mandatory=$False,ParameterSetName = 'ClientID')]
    [String]$ClientID = 'd3590ed6-52b3-4102-aeff-aad2292ab01c', 
    [Parameter(Mandatory,ParameterSetName = 'ClientSecret')]
    [String]$ClientSecret, 
    [Parameter(Mandatory=$false,ParameterSetName = 'ClientID')]
    [stirng]$RedirectURI = 'http://localhost',
    [Parameter(Mandatory=$False)]
    [String]$Resource = 'https://graph.microsoft.com',
    [Parameter(Mandatory=$False)]
    [String]$scope = 'openid'

    )

    begin{

        $UserAgent = 'Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko'
        $url = 'https://login.microsoft.com/common/oauth2/token' ##https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow

        $headers = @{
            'Accept' = 'application/json'
            'Content-Type' = 'application/x-www-form-urlencoded'
            'User-Agent' = $UserAgent
        }

        if($credential){ 
            Write-PSFMessage -Level Verbose -Message 'Initiating the User/Password authentication flow'
            $username = $credential.UserName
            $password = $credential.Password
            $passwordText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

            $body = "grant_type=password&password=$passwordText&client_id=$ClientID&username=$username&resource=$Resource&client_info=1&scope=$scope"
        }
        else {
            Write-PSFMessage -Level Verbose -Message 'Initiating the client authentication flow'
            $body = "grant_type=authorization_code&client_id=$ClientID&client_secret=$ClientSecret&resource=$Resource&client_info=1&scope=$scope"
        }
    }

    Process{
        try{
            Write-PSFMessage -Level Verbose -Message 'Trying to authenticate with the provided credentials'
            $tokens = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body

            if ($tokens) {
                $tokenPayload = $tokens.access_token.Split('.')[1].Replace('-', '+').Replace('_', '/')
                while ($tokenPayload.Length % 4) { Write-PSFMessage -Level Verbose -Message 'Invalid length for a Base-64 char array or string, adding ='; $tokenPayload += "=" }
                $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
                $tokenArray = [System.Text.Encoding]::ASCII.GetString($tokenByteArray)
                $tokobj = $tokenArray | ConvertFrom-Json
                $baseDate = Get-Date -date '01-01-1970'
                $tokenExpire = $baseDate.AddSeconds($tokobj.exp).ToLocalTime()
                Write-PSFMessage -Level Verbose -Message "Your access token is set to expire on: $tokenExpire"
            }
        } catch {
            $details = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-PSFMessage -Level Error -Message "Failed to authenticate with the provided credentials. Error: $($details.error_description)"
        }
    }

    end { 
        Write-PSFMessage -Level Verbose -Message 'Successful authentication. Access and refresh tokens have been written to the global $tokens variable.'
        $global:tokens = $tokens
    }
}
        
    

