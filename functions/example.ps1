
$cred = get-credential -Message 'Enter your credentials' -UserName 'hans.wurst@mailmarcokleinert.onmicrosoft.com'

$tennantId = '775fb56c-2847-4743-b9ff-51ffa2be3a64'



$conn = Connect-AzAccount -Credential $cred -Tenant $tennantId


$resources = Get-AzureAllResource -Connection $conn -keepAlive
$resources


