function Add-SiteColumn {
 
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$fieldXml,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $field = $web.Fields.AddFieldAsXml($fieldXml, $false, ([Microsoft.SharePoint.Client.AddFieldOptions]::AddToNoContentType))
        $ClientContext.load($field)
        $ClientContext.ExecuteQuery()
        $field
    }
    end {} 
}
function Get-SiteColumn {
 
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$fieldId,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $fields = $web.Fields
        $ClientContext.Load($fields)
        $ClientContext.ExecuteQuery()

        $field = $null
        $field = $fields | Where {$_.Id -eq $fieldId}
        $field
    }
    end {} 
}
function Remove-SiteColumn {
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$fieldId,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web, 
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $field = Get-SiteColumn -FieldId $fieldId -Web $web -ClientContext $ClientContext
        if($field -ne $null) {
            $field.DeleteObject()
            $ClientContext.ExecuteQuery()
        }
    }
}
function Remove-SiteColumns {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][System.Xml.XmlElement]$fieldsXml,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web, 
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {

        $ClientContext.Load($web.Fields)
        $ClientContext.ExecuteQuery()
        
        $deletedSiteColumns = $false
        foreach ($fieldXml in $fieldsXml.RemoveField) {
            $field = $web.Fields | Where {$_.Id -eq $fieldXml.ID}
            if($field -ne $null) {
                Write-Output "Deleting Site Column $($fieldXml.Name)"
                $field.DeleteObject()
            } else {
                Write-Verbose "Site Column $($fieldXml.Name) already deleted"
            }
        }
        if($deletedSiteColumns) {
            $ClientContext.ExecuteQuery()
            Write-Output "Deleted Site Columns"
        }
    }
}
function Update-SiteColumns {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][System.Xml.XmlElement]$fieldsXml,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web, 
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        Write-Verbose "Updating Site Columns" -Verbose
        $taxonomySession = Get-TaxonomySession -ClientContext $ClientContext
        $defaultSiteCollectionTermStore = Get-DefaultSiteCollectionTermStore -TaxonomySession $taxonomySession -ClientContext $ClientContext
        $ClientContext.Load($web.Fields)
        $ClientContext.ExecuteQuery()
        
        foreach ($fieldXml in $fieldsXml.Field) {
            $field = $web.Fields | Where {$_.Id -eq $fieldXml.ID}
	        if($field -eq $null) {
                $fieldStr = $fieldXml.OuterXml.Replace(" xmlns=`"http://schemas.microsoft.com/sharepoint/`"", "")
                $field = $web.Fields.AddFieldAsXml($fieldStr, $false, ([Microsoft.SharePoint.Client.AddFieldOptions]::AddToNoContentType))
                if(($fieldXml.Type -eq "TaxonomyFieldType") -or ($fieldXml.Type -eq "TaxonomyFieldTypeMulti")) {
                    $termSetId = $null
                    $field = [SharePointClient.PSClientContext]::CastToTaxonomyField($ClientContext, $field)
                    $field.SspId = $defaultSiteCollectionTermStore.Id
                    foreach($property in $fieldXml.Customization.ArrayOfProperty.Property) {
                        if($property.Name -eq "TermSetId") {
                            $termSetId = $property.Value.InnerText
                        }
                    }
                    if($termSetId) {                      
                        $field.TermSetId = $termSetId   
                    }
                    $field.UpdateAndPushChanges($false)
                }
                $ClientContext.ExecuteQuery()
		        Write-Verbose "Created Site Column $($fieldXml.Name)" -Verbose
	        } else {
                $updatedField = $false
                if($fieldXml.Name -ne $field.InternalName) {
                    $SchemaXml = $field.SchemaXml
                    $SchemaXml = $SchemaXml -replace " Name=""$($field.InternalName)"" ", " Name=""$($fieldXml.Name)"" "
                    Write-Verbose "Updating field schema xml $($SchemaXml)" -Verbose
                    $field.SchemaXml = $SchemaXml
                    $field.UpdateAndPushChanges($true)
                    $ClientContext.Load($field)
                    $ClientContext.ExecuteQuery()
                    $updatedField = $true
                    
                }
                if($fieldXml.Name -ne $field.StaticName) {
                    $field.StaticName = $fieldXml.Name
                    $updatedField = $true
                }
                if($fieldXml.DisplayName -ne $field.Title) {
                    $field.Title = $fieldXml.DisplayName
                    $updatedField = $true
                }
                if($fieldXml.UnlimitedLengthInDocumentLibrary) {
                    $unlimitedLengthInDocumentLibrary = [bool]::Parse($fieldXml.UnlimitedLengthInDocumentLibrary)
                    if($field.UnlimitedLengthInDocumentLibrary -ne $unlimitedLengthInDocumentLibrary) {
                        #TODO Append SchemaXml UnlimitedLengthInDocumentLibrary="True"
                        #$updatedField = $true
                    }
                }
                if($updatedField) {
                    $field.UpdateAndPushChanges($true)
                    $ClientContext.ExecuteQuery()
                    Write-Verbose "Updated Site Column $($fieldXml.Name)" -Verbose
                } else {
		            Write-Verbose "Site Column $($fieldXml.Name) already exists"
                }
	        }
        }
        Write-Verbose "Updated Site Columns" -Verbose
    }
}