function Add-Site {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.Online.SharePoint.TenantAdministration.SiteCreationProperties]$SiteCreationProperties,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        #$tenantAdmin = [SharePointClient.PSTenant]::Tenant($adminContext)
        $tenantAdmin = New-Object Microsoft.Online.SharePoint.TenantAdministration.Tenant($ClientContext)

        $spoOperation = $tenantAdmin.CreateSite($SiteCreationProperties)
        $ClientContext.Load($tenantAdmin)
        $ClientContext.Load($spoOperation)
        $ClientContext.ExecuteQuery()

        while ($spoOperation.IsComplete -eq $false)
        {
            Start-Sleep -s 30
            $spoOperation.RefreshLoad()
            $ClientContext.ExecuteQuery()
        }
    }
}