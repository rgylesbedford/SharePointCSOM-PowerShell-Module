function Add-PSClientContext {
    $assemblies = @( 
        [System.Reflection.Assembly]::GetAssembly([Microsoft.SharePoint.Client.ClientContext]).FullName,
        [System.Reflection.Assembly]::GetAssembly([Microsoft.SharePoint.Client.Taxonomy.TaxonomyField]).FullName,
        [System.Reflection.Assembly]::GetAssembly([Microsoft.SharePoint.Client.ClientRuntimeContext]).FullName
    )
    Add-Type -ReferencedAssemblies $assemblies -TypeDefinition @"
using Microsoft.SharePoint.Client;
using Microsoft.SharePoint.Client.Taxonomy;
namespace SharePointClient
{
    public class PSClientContext: ClientContext
    {
        public PSClientContext(string siteUrl)
            : base(siteUrl)
        {
        }
        // need a plain Load method here, the base method is a generic method
        // which isn't supported in PowerShell.
        public void Load(ClientObject objectToLoad)
        {
            base.Load(objectToLoad);
        }
        public static TaxonomyField CastToTaxonomyField (ClientContext ctx, Field field)
        {
            return ctx.CastTo<TaxonomyField>(field);
        }
        public static void Load (ClientContext ctx, ClientObject objectToLoad)
        {
            ctx.Load(objectToLoad);
        }
        public TaxonomyField CastToTaxonomyField (Field field)
        {
            return base.CastTo<TaxonomyField>(field);
        }
        public static Folder loadContentTypeOrderForFolder(Folder folder, ClientContext ctx) {
            ctx.Load(folder, f => f.UniqueContentTypeOrder, f => f.ContentTypeOrder);
            ctx.ExecuteQuery();
            return folder;
        }
        public static void CreateWebRoleAssignment(ClientContext clientContext, Web web, string groupName, string roleDefName) {
            clientContext.Load(web);
            clientContext.ExecuteQuery(); 
            
            var grp = web.SiteGroups.GetByName(groupName);
            
            RoleDefinitionBindingCollection rdb = new RoleDefinitionBindingCollection(clientContext);
            rdb.Add(web.RoleDefinitions.GetByName(roleDefName));
            web.RoleAssignments.Add(grp, rdb);
            
            clientContext.ExecuteQuery(); 

        } 
        public static void CreateListRoleAssignment(ClientContext clientContext, Web web, List list, Principal principal, string roleDefName) {
            RoleDefinitionBindingCollection rdb = new RoleDefinitionBindingCollection(clientContext);
            rdb.Add(web.RoleDefinitions.GetByName(roleDefName));
            list.RoleAssignments.Add(principal, rdb);
            
            clientContext.ExecuteQuery(); 

        } 
        public static void AddUserToGroup(ClientContext clientContext, Web web, string groupName, string userLoginName) {
            
            var grp = web.SiteGroups.GetByName(groupName);
            clientContext.Load(grp);
            clientContext.ExecuteQuery(); 
            
		    grp.Users.Add(new UserCreationInformation() {LoginName = userLoginName});
		    grp.Update();
            
            clientContext.ExecuteQuery(); 

        } 
        public static bool ListHasUniqueRoleAssignments(ClientContext clientContext, Web web, List list) {
            clientContext.Load(list, l => l.HasUniqueRoleAssignments);
            clientContext.ExecuteQuery(); 
            return list.HasUniqueRoleAssignments;
        } 
    }
}
"@

}


function Add-CSOM {
    $CSOMdir = "${env:CommonProgramFiles}\microsoft shared\Web Server Extensions\16\ISAPI"
    $excludeDlls = "*.Portable.dll"
    
    if ((Test-Path $CSOMdir -pathType container) -ne $true)
    {
        $CSOMdir = "${env:CommonProgramFiles}\microsoft shared\Web Server Extensions\15\ISAPI"
        if ((Test-Path $CSOMdir -pathType container) -ne $true)
        {
            Throw "Please install the SharePoint 2013[1] or SharePoint Online[2] Client Components SDK`n `n[1] http://www.microsoft.com/en-us/download/details.aspx?id=35585`n[2] http://www.microsoft.com/en-us/download/details.aspx?id=42038`n `n "
        }
    }
    
    
    $CSOMdlls = Get-Item "$CSOMdir\*.dll" -exclude $excludeDlls
    
    ForEach ($dll in $CSOMdlls) {
        [System.Reflection.Assembly]::LoadFrom($dll.FullName) | Out-Null
    }

    Add-PSClientContext
    
}

function Add-TenantCSOM {
    $tenantDllPath = "${env:ProgramFiles}\SharePoint Client Components\16.0\Assemblies"
    if((Test-Path $tenantDllPath -pathType container) -ne $true) {
        Throw "Please install the SharePoint Online Client Components SDK[1]`n `n[1] http://www.microsoft.com/en-us/download/details.aspx?id=42038`n `n "
    }

    $tenantDll =  Get-Item "$tenantDllPath\Microsoft.Online.SharePoint.Client.Tenant.dll"
    [System.Reflection.Assembly]::LoadFrom($tenantDll.FullName) | Out-Null

}

function Add-PreloadedSPdlls {
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") | Out-Null
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Taxonomy") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Publishing") | Out-Null
    
    Add-PSClientContext
}


function Add-PreloadedSPTenantdlls {
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Online.SharePoint.Client.Tenant") | Out-Null

}

function Add-InternalDlls {
    param(
    [parameter(Mandatory=$true, ValueFromPipeline=$true)][string] $assemblyPath
    )
    process {
        $internalDlls = Get-Item "$assemblyPath\*.dll"
    
        ForEach ($dll in $internalDlls) {
            [System.Reflection.Assembly]::LoadFrom($dll.FullName) | Out-Null
        }
    }
}