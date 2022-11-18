#Import the Azure AD Module
Install-Module AzureADPreview -AllowClobber -Force
Import-Module AzureADPreview -Force -Verbose
#Connect to Azure AD
Connect-AzureAD -AccountId marco.kleinert@netz-weise.de -TenantId 'b7f24275-fb73-432a-8300-44301f23be7a'
Get-AzTenant
$audits = Get-AzureADAuditSignInLogs
$audits | select CreatedDateTime, UserPrincipalName, IsInteractive, AppDisplayName, IpAddress, TokenIssuerType, @{Name = 'DeviceOS'; Expression = {$_.DeviceDetail.OperatingSystem}} | ConvertTo-Csv -Delimiter ';' -NoTypeInformation | clip


Disconnect-AzAccount