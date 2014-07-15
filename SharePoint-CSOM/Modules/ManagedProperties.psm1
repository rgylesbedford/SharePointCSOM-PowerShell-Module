function Update-ManagedProperty {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][string]$ManagedPropertyName,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][string]$CrawledProperties = "",
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][string]$Level = "tenant",
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][string]$Alias = "",
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    begin {
    }
    process {
        $managedProperty = New-Object SharePointCSOM.Remote.Core.HttpCommands.RequestManagedPropertySettings($ClientContext.Url, $ClientContext.Credentials);
        $managedProperty.ManagedProperty = $ManagedPropertyName #"RefinableString99";
        $managedProperty.CrawledProperties = $CrawledProperties #'"ows_Title"+"00130329-0000-0130-c000-000000131346;ows_Title"+'#"People:JLLRegion"+"00110329-0000-0110-c000-000000111146;urn:schemas-microsoft-com:sharepoint:portal:profile:JLLRegion"+';
        $managedProperty.Level = $Level;
        $managedProperty.Alias = $Alias;
        $managedProperty.Execute();
    }
    end {}
}