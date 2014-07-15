function Get-ContentType {
 
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ContentTypeName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $contentTypes = $web.AvailableContentTypes
        $ClientContext.Load($contentTypes)
        $ClientContext.ExecuteQuery()

        $contentType = $contentTypes | Where {$_.Name -eq $ContentTypeName}
        $contentType
    }
    end {}
}
function Get-ContentTypeWithID {
 
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ContentTypeID,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $contentTypes = $web.AvailableContentTypes
        $ClientContext.Load($contentTypes)
        $ClientContext.ExecuteQuery()

        $contentType = $contentTypes | Where {$_.Id -eq $ContentTypeID}
        $contentType
    }
    end {}
}
function Remove-ContentType {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ContentTypeName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web, 
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        
        $contentType = Get-ContentType -ContentTypeName $ContentTypeName -Web $web -ClientContext $ClientContext
        if($contentType -ne $null) {
            $contentType.DeleteObject()
            $ClientContext.ExecuteQuery()
        }
    }
    end {}
}
function Add-ContentType {
 
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Name,
        [parameter(ValueFromPipeline=$true)][string]$Description = "Create a new $Name",
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Group,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ParentContentTypeName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        
        $parentContentType = Get-ContentType -ContentTypeName $ParentContentTypeName -Web $web -ClientContext $ClientContext
        $contentType = $null
        if($parentContentType -eq $null) {
            Write-Warning "Error loading parent content type $ParentContentTypeName" -WarningAction Continue
        } else {

            $contentTypeCreationInformation = New-Object Microsoft.SharePoint.Client.ContentTypeCreationInformation
            $contentTypeCreationInformation.Name = $Name
            $contentTypeCreationInformation.Description = "Create a new $Name"
            $contentTypeCreationInformation.Group = $Group
            $contentTypeCreationInformation.ParentContentType = $parentContentType
            
            $contentType = $web.ContentTypes.Add($contentTypeCreationInformation)
            $ClientContext.load($contentType)
            $ClientContext.ExecuteQuery()
        }
        $contentType
    }
    end {}
}
function Add-ContentTypeWithID {
 
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Name,
        [parameter(ValueFromPipeline=$true)][string]$Description = "Create a new $Name",
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Group,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ID,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        
        $contentTypeCreationInformation = New-Object Microsoft.SharePoint.Client.ContentTypeCreationInformation
        $contentTypeCreationInformation.Name = $Name
        $contentTypeCreationInformation.Description = "Create a new $Name"
        $contentTypeCreationInformation.Group = $Group
        $contentTypeCreationInformation.ID = $ID
            
        $contentType = $web.ContentTypes.Add($contentTypeCreationInformation)
        $ClientContext.load($contentType)
        $ClientContext.ExecuteQuery()

        $contentType
    }
    end {}
}

function Add-FieldToContentType {
 
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$FieldId,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ContentType]$ContentType,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        
        $field = Get-SiteColumn -fieldId $FieldId -Web $web -ClientContext $ClientContext
        $fieldlink = $null
        if($field -eq $null) {
            Write-Warning "Error getting field $FieldId" -ErrorAction Continue
        } else {
            $ClientContext.Load($ContentType.FieldLinks)
            $ClientContext.ExecuteQuery()
            $fieldlinkCreation = New-Object Microsoft.SharePoint.Client.FieldLinkCreationInformation
            $fieldlinkCreation.Field = $field
            $fieldlink = $ContentType.FieldLinks.Add($fieldlinkCreation)
            $ContentType.Update($true)
            $ClientContext.ExecuteQuery()
        }
        $fieldlink
    }
    end {}
}
function Get-FieldForContentType {
 
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$FieldId,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ContentType]$ContentType,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $fields = $ContentType.Fields
        $ClientContext.Load($fields)
        $ClientContext.ExecuteQuery()

        $field = $null
        $field = $fields | Where {$_.Id -eq $FieldId}
        $field
    }
    end {}
}
function Remove-FieldFromContentType {
 
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$FieldId,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ContentType]$ContentType,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $fieldLinks = $ContentType.FieldLinks
        $ClientContext.Load($fieldLinks)
        $ClientContext.ExecuteQuery()

        $fieldLink = $fieldLinks | Where {$_.Id -eq $FieldId}
        if($fieldLink -ne $null) {
            $fieldLink.DeleteObject()
            $ContentType.Update($true)
            $ClientContext.ExecuteQuery()
            Write-Verbose "Deleted field $fieldId from content type $($ContentType.Name)" -Verbose
        } else {
            Write-Verbose "Field $fieldId already deleted from content type $($ContentType.Name)"
        }
    }
    end {}
}
function Update-ContentTypeFieldLink {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][System.Nullable[bool]]$Required,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][System.Nullable[bool]]$Hidden,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.FieldLink]$FieldLink,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ContentType]$ContentType,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        if($fieldLink -ne $null) {      
            $needsUpdating = $false
            if($Required -ne $null -and $fieldLink.Required -ne $Required) {
                $fieldLink.Required = $Required
                $needsUpdating = $true
            }
            if($Hidden -ne $null -and $fieldLink.Hidden -ne $Hidden) {
                $fieldLink.Hidden = $Hidden
                $needsUpdating = $true
            }
            if($needsUpdating) {
                $ContentType.Update($true)
                $ClientContext.ExecuteQuery()
                Write-Verbose "`tUpdated field link $fieldId for content type $($ContentType.Name)" -Verbose
            } else {
                Write-Verbose "`tDid not update field link $fieldId for content type $($ContentType.Name)"
            }
        } else {
            Write-Warning "Could not find field link $fieldId for content type $($ContentType.Name)" -WarningAction Continue
        }
    }
    end {}
}

function Remove-ContentTypes {
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][System.Xml.XmlElement]$contentTypesXml,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $ClientContext.Load($web.ContentTypes)
        $ClientContext.ExecuteQuery()

        # delete content types
        $contentTypesDeleted = $false
        foreach ($contentTypeXml in $contentTypesXml.RemoveContentType) {
            $contentType = $web.ContentTypes | Where {$_.Name -eq $ContentTypeXml.Name}
            if($contentType -ne $null) {
                 $contentType.DeleteObject()
                 $contentTypesDeleted = $true
            }
        }
        if($contentTypesDeleted) {
            $ClientContext.Load($web.ContentTypes)
            $ClientContext.ExecuteQuery()
        }
    }

}

function Update-ContentTypes {
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][System.Xml.XmlElement]$contentTypesXml,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $ClientContext.Load($web.ContentTypes)
        $ClientContext.Load($web.AvailableContentTypes)
        $ClientContext.Load($web.Fields)
        $ClientContext.ExecuteQuery()

        # delete content types
        $contentTypesDeleted = $false
        foreach ($contentTypeXml in $contentTypesXml.RemoveContentType) {
            $contentType = $web.ContentTypes | Where {$_.Name -eq $ContentTypeXml.Name}
            if($contentType -ne $null) {
                 $contentType.DeleteObject()
                 $contentTypesDeleted = $true
            }
        }
        if($contentTypesDeleted) {
            $ClientContext.Load($web.ContentTypes)
            $ClientContext.Load($web.AvailableContentTypes)
            $ClientContext.ExecuteQuery()
        }

        # Now add / update content types
        foreach ($contentTypeXml in $contentTypesXml.ContentType) {
            $contentType = $null

            # Perfer using content type id
            if($ContentType.ID) {
                $contentType = $web.ContentTypes | Where {$_.Id -eq $contentTypeXml.ID}
            }

            # Try using content type name
            if($contentType -eq $null) {
                $contentType = $web.ContentTypes | Where {$_.Name -eq $contentTypeXml.Name}
            }

            # need to create it
            if($contentType -eq $null) {
                
                # check to see if we have the parent content type avilable, if not, then can't create content type.
                $parentContentType = $web.AvailableContentTypes | Where {$_.Name -eq $contentTypeXml.ParentContentType}
                if($parentContentType -ne $null) {

                    $contentTypeCreationInformation = New-Object Microsoft.SharePoint.Client.ContentTypeCreationInformation
                    $contentTypeCreationInformation.Name = $contentTypeXml.Name
                    $contentTypeCreationInformation.Group = $contentTypeXml.Group

                    if($contentTypeXml.Description) {
                        $contentTypeCreationInformation.Description = $contentTypeXml.Description
                    } else {
                        $contentTypeCreationInformation.Description = "Create a new $Name"
                    }
                
                
                
                    if($contentTypeXml.ID) {
                        $contentTypeCreationInformation.ID = $contentTypeXml.ID
                    } else {
                        $contentTypeCreationInformation.ParentContentType = $parentContentType
                    }

                    $contentType = $web.ContentTypes.Add($contentTypeCreationInformation)
                    
                    $ClientContext.load($contentType)
                    $ClientContext.Load($web.ContentTypes)
                    $ClientContext.Load($web.AvailableContentTypes)
                    $ClientContext.ExecuteQuery()

                    if($contentType -eq $null) {
                        Write-Error "Could Not Create Content Type $($ContentType.Name)"
                    } else {
                        Write-Verbose "Created Content Type $($ContentType.Name)" -Verbose
                    }
                } else {
                    Write-Warning "Skipping Content Type $($contentTypeXml.Name), parent content type $($contentTypeXml.ParentContentType) unavilable" -WarningAction Continue
                }
            # rename if needed
            } elseif ($contentType.Name -ne $contentTypeXml.Name) {
                $contentType.Name = $contentTypeXml.Name
                $contentType.Update($true)
                $ClientContext.load($contentType)
                $ClientContext.Load($web.ContentTypes)
                $ClientContext.Load($web.AvailableContentTypes)
                $ClientContext.ExecuteQuery()
                Write-Verbose "Renamed Content Type $($ContentType.Name) ." -Verbose
            } else {
                Write-Verbose "Content Type $($ContentType.Name)  already created."
            }

            ## add / edit/ remove fieldlinks if we have a content type
            if($contentType -ne $null) {
                $ClientContext.Load($contentType.Fields)
                $ClientContext.Load($contentType.FieldLinks)
                $ClientContext.ExecuteQuery()


                # Delete fieldLinks
                $fieldLinksRemoved = $false
                foreach ($removeFieldRefXml in $contentTypeXml.FieldRefs.RemoveFieldRef) {
                    $fieldLinkToRemove = $contentType.FieldLinks | Where {$_.Id -eq $removeFieldRefXml.ID}
                    if($fieldLinkToRemove -ne $null) {
                        $fieldLinkToRemove.DeleteObject()
                        $fieldLinksRemoved = $true
                        Write-Verbose "Deleted field $($removeFieldRefXml.ID) from content type $($ContentType.Name)" -Verbose
                    } else {
                        Write-Verbose "Field $($removeFieldRefXml.ID) already deleted from content type $($ContentType.Name)"
                    }
                }
                if($fieldLinksRemoved) {
                    $contentType.Update($true)
                    $ClientContext.Load($contentType.FieldLinks)
                    $ClientContext.Load($contentType.Fields)
                    $ClientContext.ExecuteQuery()
                }


                # Add fieldLinks
                $fieldLinksAdded = $false
                foreach ($fieldRefXml in $contentTypeXml.FieldRefs.FieldRef) {
                    $field = $contentType.Fields | Where {$_.Id -eq $fieldRefXml.ID}
                
                    if($field -eq $null) {
                        $webField = $web.Fields | Where {$_.Id -eq $fieldRefXml.ID}
                        $fieldlinkCreation = New-Object Microsoft.SharePoint.Client.FieldLinkCreationInformation
                        $fieldlinkCreation.Field = $webField
                        $fieldlink = $contentType.FieldLinks.Add($fieldlinkCreation)
                        $fieldLinksAdded = $true

                        Write-Verbose "`tAdded field $($fieldRefXml.ID) to Content Type $($ContentType.Name)" -Verbose
                    } else {
                        Write-Verbose "`tField $($fieldRefXml.ID) already added to Content Type $($ContentType.Name)"
                    }
                }
                if($fieldLinksAdded) {
                    $contentType.Update($true)
                    $ClientContext.Load($contentType.Fields)
                    $ClientContext.Load($contentType.FieldLinks)
                    $ClientContext.ExecuteQuery()
                }

                # Update fieldLinks
                $needsUpdating = $false
                foreach ($fieldRefXml in $contentTypeXml.FieldRefs.FieldRef) {
                
                    $fieldLink = $contentType.FieldLinks | Where {$_.Id -eq $fieldRefXml.ID}

                    $Required = $null
                    if($fieldRefXml.Required) {
                        $Required = [bool]::Parse($fieldRefXml.Required)
                    }
                    $Hidden = $null
                    if($fieldRefXml.Hidden) {
                        $Hidden = [bool]::Parse($fieldRefXml.Hidden)
                    }

                    if($fieldLink -ne $null) {      

                        if($Required -ne $null -and $fieldLink.Required -ne $Required) {
                            $fieldLink.Required = $Required
                            $needsUpdating = $true
                        }
                        if($Hidden -ne $null -and $fieldLink.Hidden -ne $Hidden) {
                            $fieldLink.Hidden = $Hidden
                            $needsUpdating = $true
                        }
                        if($needsUpdating) {
                            Write-Verbose "`tUpdated field link $($fieldRefXml.ID) for content type $($contentType.Name)" -Verbose
                        } else {
                            Write-Verbose "`tDid not update field link $($fieldRefXml.ID) for content type $($contentType.Name)"
                        }
                    } else {
                        Write-Error "Could not find field link $($fieldRefXml.ID) for content type $($contentType.Name)"
                    }
                }
                if($needsUpdating) {
                    $ContentType.Update($true)
                    $ClientContext.ExecuteQuery()
                    Write-Verbose "`tUpdated field links for content type $($contentType.Name)" -Verbose
                } else {
                    Write-Verbose "`tDid not update field links for content type $($contentType.Name)"
                }
            }
        }
    }
}