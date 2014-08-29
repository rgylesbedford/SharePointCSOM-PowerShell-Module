function Set-BreakRoleInheritance  {
    <#
    http://msdn.microsoft.com/en-us/library/office/microsoft.sharepoint.client.securableobject.breakroleinheritance(v=office.15).aspx
    #>
    param (
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][bool] $copyRoleAssignments = $true,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][bool] $clearSubscopes = $true,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.SecurableObject] $securableObject,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $securableObject.BreakRoleInheritance($copyRoleAssignments, $clearSubscopes)
        $clientContext.ExecuteQuery();
    }
    end {} 
}
function Reset-RoleInheritance  {
    <#
    http://msdn.microsoft.com/en-us/library/office/microsoft.sharepoint.client.securableobject.resetroleinheritance(v=office.15).aspx
    #>
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.SecurableObject] $securableObject,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $securableObject.ResetRoleInheritance()
        $clientContext.ExecuteQuery();
    }
    end {} 
}

function Get-SiteGroup {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$GroupName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $groups = $web.SiteGroups
        $ClientContext.Load($groups);
        $ClientContext.ExecuteQuery();
        $group = $groups | Where {$_.Title -eq $GroupName}
        $group
    }
}

function New-SiteGroup {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$GroupName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $groupCreationInformation = New-Object Microsoft.SharePoint.Client.GroupCreationInformation
        $groupCreationInformation.Title = $GroupName
        $spGroup = $web.SiteGroups.Add($groupCreationInformation)
        $spGroup.Update();
        $ClientContext.Load($spGroup);
        $ClientContext.ExecuteQuery();
        $spGroup
    }
}