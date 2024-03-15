
$cred = get-credential -Message 'Enter your credentials' -UserName 'hans.wurst@mailmarcokleinert.onmicrosoft.com'
$tennantId = '775fb56c-2847-4743-b9ff-51ffa2be3a64'

## create initial connection
$connection = Connect-AzAccount -Credential $cred -Tenant $tennantId
SignIn $connection
## get all resources examples
$resources = Get-AzureAllResource -Connection $connection -keepAlive -Verbose 
$resources

## get all resources with expired tag
Add-AzureExpiredTag -TenantID $tennantId -expireOn '2024/12/31' -Verbose

Remove-AzureAllTag -TenantID $tennantId -Verbose