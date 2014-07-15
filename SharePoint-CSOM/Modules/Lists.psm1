function New-List {
 
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)][string]$ListName,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)][string]$Type,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)][string]$Url,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][guid]$TemplateFeatureId,           
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext

   )
    process {
        
        $listCreationInformation = New-Object Microsoft.SharePoint.Client.ListCreationInformation
        $listCreationInformation.Title = $ListName
        $listCreationInformation.TemplateType = $Type
        $listCreationInformation.Url = $Url
        
        if($TemplateFeatureId) {
            $listCreationInformation.TemplateFeatureId = $TemplateFeatureId
        }

        New-ListWithListCreationInformation -listCreationInformation $listCreationInformation -web $web -ClientContext $ClientContext
    }
    end {}
}
function New-ListFromXml {
 
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][System.Xml.XmlElement]$listxml,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
   )
    process {
        
        $listCreationInformation = New-Object Microsoft.SharePoint.Client.ListCreationInformation
        if($listxml.Description) {
            $listCreationInformation.Description = $listxml.Description
        }
        if($listxml.OnQuickLaunchBar) {
            $onQuickLaunchBar = [bool]::Parse($listxml.OnQuickLaunchBar)
            if($onQuickLaunchBar){
                $listCreationInformation.QuickLaunchOption = [Microsoft.SharePoint.Client.QuickLaunchOptions]::On
            } elseif(!$onQuickLaunchBar) {
                $listCreationInformation.QuickLaunchOption = [Microsoft.SharePoint.Client.QuickLaunchOptions]::Off
            }
        }
        if($listxml.QuickLaunchOption) {
            $listCreationInformation.QuickLaunchOption = [Microsoft.SharePoint.Client.QuickLaunchOptions]::$($listxml.QuickLaunchOption)
        }
        if($listxml.TemplateFeatureId) {
            $listCreationInformation.TemplateFeatureId = $listxml.TemplateFeatureId
        }
        if($listxml.Type) {
            $listCreationInformation.TemplateType = $listxml.Type
        }
        if($listxml.Title) {
            $listCreationInformation.Title = $listxml.Title
        }
        if($listxml.Url) {
            $listCreationInformation.Url = $listxml.Url
        }

        New-ListWithListCreationInformation -listCreationInformation $listCreationInformation -web $web -ClientContext $ClientContext
    }
    end {}
}
function New-ListWithListCreationInformation {
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ListCreationInformation]$listCreationInformation,           
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext

   )
    process {

        $list = $web.Lists.Add($listCreationInformation)
        
        $ClientContext.Load($list)
        $ClientContext.ExecuteQuery()
        
        $list
    }
    end {}
}
function Get-List {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ListName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $lists = $web.Lists
        $ClientContext.Load($lists)
        $ClientContext.ExecuteQuery()
        
        $list = $null
        $list = $lists | Where {$_.Title -eq $ListName}
        if($list -ne $null) {
            $ClientContext.Load($list)
            $ClientContext.ExecuteQuery()
        }
        $list
    }
}
function Remove-List {
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ListName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web, 
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $list = Get-List -ListName $ListName -Web $web -ClientContext $ClientContext
        if($list -ne $null) {
            $list.DeleteObject()
            $ClientContext.ExecuteQuery()
        }
    }
}

function Get-ListView {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ViewName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $views = $list.Views
        $ClientContext.load($views)
        $ClientContext.ExecuteQuery()
        
        $view = $null
        $view = $views | Where {$_.Title -eq $ViewName}
        if($view -ne $null) {
            $ClientContext.load($view)
            $ClientContext.ExecuteQuery()
        }
        $view
    }
}
function New-ListView {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ViewName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][bool]$DefaultView,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][bool]$Paged,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][bool]$PersonalView,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Query,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][int]$RowLimit,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string[]]$ViewFields,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ViewType,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        
        $ViewTypeKind
        switch($ViewType) {
            "none"{$ViewTypeKind = [Microsoft.SharePoint.Client.ViewType]::None}
            "html"{$ViewTypeKind = [Microsoft.SharePoint.Client.ViewType]::Html}
            "grid"{$ViewTypeKind = [Microsoft.SharePoint.Client.ViewType]::Grid}
            "calendar"{$ViewTypeKind = [Microsoft.SharePoint.Client.ViewType]::Calendar}
            "recurrence"{$ViewTypeKind = [Microsoft.SharePoint.Client.ViewType]::Recurrence}
            "chart"{$ViewTypeKind = [Microsoft.SharePoint.Client.ViewType]::Chart}
            "gantt"{$ViewTypeKind = [Microsoft.SharePoint.Client.ViewType]::Gantt}
        }
        $vCreation = New-Object Microsoft.SharePoint.Client.ViewCreationInformation
        $vCreation.Paged = $Paged
        $vCreation.PersonalView = $PersonalView
        $vCreation.Query = $Query
        $vCreation.RowLimit = $RowLimit
        $vCreation.SetAsDefaultView = $DefaultView
        $vCreation.Title = $ViewName
        $vCreation.ViewFields = $ViewFields
        $vCreation.ViewTypeKind = $ViewTypeKind

        $view = $list.Views.Add($vCreation)
        $list.Update()
        $ClientContext.ExecuteQuery()
        $view
    }
}
function Update-ListView {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ViewName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][bool]$DefaultView,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][bool]$Paged,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Query,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][int]$RowLimit,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string[]]$ViewFields,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        
        $view = Get-ListView -List $List -ViewName $ViewName -ClientContext $ClientContext
        
        if($view -ne $null) {
            $view.Paged = $Paged
            $view.ViewQuery = $Query
            $view.RowLimit = $RowLimit
            $view.DefaultView = $DefaultView
            #Write-Host $ViewFields
            $view.ViewFields.RemoveAll()
            ForEach ($vf in $ViewFields) {
                $view.ViewFields.Add($vf)
                #$ctx.Load($view.ViewFields)
                #$view.Update()
                #$List.Update()
                #$ClientContext.ExecuteQuery()
                #Write-Host "Add column $vf to view"
                #Write-Host $view.ViewFields
            }

            $view.Update()
            $List.Update()
            $ClientContext.ExecuteQuery()
        }
        $view
    }
}

function Get-ListContentType {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ContentTypeName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $contentTypes = $List.ContentTypes
        $ClientContext.load($contentTypes)
        $ClientContext.ExecuteQuery()
        
        $contentType = $null
        $contentType = $contentTypes | Where {$_.Name -eq $ContentTypeName}
        if($contentType -ne $null) {
            $ClientContext.load($contentType)
            $ClientContext.ExecuteQuery()
        }
        $contentType
    }
}
function Add-ListContentType {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ContentTypeName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext

   )
    process {
        $contentTypes = $web.AvailableContentTypes
        $ClientContext.Load($contentTypes)
        $ClientContext.ExecuteQuery()

        $contentType = $contentTypes | Where {$_.Name -eq $ContentTypeName}
        if($contentType -ne $null) {
            if(!$List.ContentTypesEnabled) {
                $List.ContentTypesEnabled = $true
            }
            $ct = $List.ContentTypes.AddExistingContentType($contentType);
            $List.Update()
            $ClientContext.ExecuteQuery()
        } else {
            $ct = $null
        }
        $ct
    }
    end {}
}
function Remove-ListContentType {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ContentTypeName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext

   )
    process {
        $contentTypeToDelete = Get-ListContentType $List $ClientContext -ContentTypeName $ContentTypeName
        
        if($contentTypeToDelete -ne $null) {
            if($contentTypeToDelete.Sealed) {
                $contentTypeToDelete.Sealed = $false
            }
            $contentTypeToDelete.DeleteObject()
            $List.Update()
            $ClientContext.ExecuteQuery()
        }
    }
}

function New-ListField {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$FieldXml,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
   )
    process {
        $field = $list.Fields.AddFieldAsXml($FieldXml, $true, ([Microsoft.SharePoint.Client.AddFieldOptions]::DefaultValue))
        $ClientContext.Load($field)
        $ClientContext.ExecuteQuery()
        $field
    }
    end {}
}
function Get-ListField {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$FieldName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $Fields = $List.Fields
        $ClientContext.Load($Fields)
        $ClientContext.ExecuteQuery()
        
        $Field = $null
        $Field = $Fields | Where {$_.InternalName -eq $FieldName}
        $Field
    }
}
function Remove-ListField {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$FieldName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $Fields = $List.Fields
        $ClientContext.Load($Fields)
        $ClientContext.ExecuteQuery()
        
        $Field = $null
        $Field = $Fields | Where {$_.InternalName -eq $FieldName}
        if($Field -ne $null) {
            $Field.DeleteObject()
            $List.Update()
            $ClientContext.ExecuteQuery()
            Write-Verbose "`t`tDeleted List Field: $FieldName" -Verbose
        } else {
            Write-Verbose "`t`tField not found in list: $FieldName"
        }
    }
}

function Update-List {
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][System.Xml.XmlElement]$listxml,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $SPList = Get-List -ListName $listxml.Title -Web $web -ClientContext $ClientContext
        if($SPList -eq $null) {
            $SPList = New-ListFromXml -listxml $listxml -Web $web -ClientContext $ClientContext
            Write-Verbose "List created: $($listxml.Title)" -Verbose
        } else {
            Write-Verbose "`List already created: $($listxml.Title)" -Verbose
        }

        $MajorVersionsEnabled = $SPList.EnableVersioning
        $MinorVersionsEnabled = $SPList.EnableMinorVersions
        $ContentApprovalEnabled = $SPList.EnableModeration
        $CheckOutRequired = $SPList.ForceCheckout

        Write-Verbose "`tContent Types" -Verbose
	    foreach ($ct in $listxml.ContentType) {
            $spContentType = Get-ListContentType -List $SPList -ContentTypeName $ct.Name -ClientContext $ClientContext
		    if($spContentType -eq $null) {
                $spContentType = Add-ListContentType -List $SPList -ContentTypeName $ct.Name -Web $web -ClientContext $ClientContext
                if($spContentType -eq $null) {
                    Write-Error "`t`tContent Type could not be added: $($ct.Name)"
                } else {
                    Write-Verbose "`t`tContent Type added: $($ct.Name)" -Verbose
                }
            } else {
                Write-Verbose "`t`tContent Type already added: $($ct.Name)"
            }

            if($spContentType -ne $null -and $ct.Default -and [bool]::Parse($ct.Default)) {
                $newDefaultContentType = $spContentType.Id
                $folder = [SharePointClient.PSClientContext]::loadContentTypeOrderForFolder($SPList.RootFolder, $ClientContext)
                $currentContentTypeOrder = $folder.ContentTypeOrder
                $newDefaultContentTypeId = $null
                foreach($contentTypeId in $currentContentTypeOrder) {
                    if($($contentTypeId.StringValue).StartsWith($newDefaultContentType)) {
                        $newDefaultContentTypeId = $contentTypeId
                        break;
                    }
                }
                if($newDefaultContentTypeId) {
                    $currentContentTypeOrder.remove($newDefaultContentTypeId)
                    $currentContentTypeOrder.Insert(0, $newDefaultContentTypeId)
                    $folder.UniqueContentTypeOrder = $currentContentTypeOrder
                    $folder.Update()
                    $ClientContext.ExecuteQuery()
                }
            }
	    }
        foreach ($ct in $listxml.RemoveContentType) {
            $spContentType = Get-ListContentType -List $SPList -ContentTypeName $ct.Name -ClientContext $ClientContext
		    if($spContentType -ne $null) {
                Remove-ListContentType -List $SPList -ContentTypeName $ct.Name -ClientContext $ClientContext
                Write-Verbose "`t`tContent Type deleted: $($ct.Name)" -Verbose
            } else {
                Write-Verbose "`t`tContent Type already deleted: $($ct.Name)"
            }
        }

        
        Write-Verbose "`tFields" -Verbose
        foreach($field in $listxml.Fields.Field){
            $spField = Get-ListField -List $SPList -FieldName $Field.Name -ClientContext $ClientContext
            if($spField -eq $null) {
                $fieldStr = $field.OuterXml.Replace(" xmlns=`"http://schemas.microsoft.com/sharepoint/`"", "")
                $spField = New-ListField -FieldXml $fieldStr -List $splist -ClientContext $ClientContext
                Write-Verbose "`t`tCreated Field: $($Field.DisplayName)" -Verbose
            } else {
                Write-Verbose "`t`tField already added: $($Field.DisplayName)"
            }
        }
        foreach($Field in $listxml.Fields.UpdateField) {
            $spField = Get-ListField -List $SPList -FieldName $Field.Name -ClientContext $ClientContext
            $needsUpdate = $false
            if($Field.ValidationFormula) {
                $ValidationFormula = $Field.ValidationFormula
                $ValidationFormula = $ValidationFormula -replace "&lt;","<"
                $ValidationFormula = $ValidationFormula -replace "&gt;",">"
                $ValidationFormula = $ValidationFormula -replace "&amp;","&"
                if($spField.ValidationFormula -ne $ValidationFormula) {
                    $spField.ValidationFormula = $ValidationFormula
                    $needsUpdate = $true
                }
            }

            if($Field.ValidationMessage) {
                if($spField.ValidationMessage -ne $Field.ValidationMessage) {
                    $spField.ValidationMessage = $Field.ValidationMessage
                    $needsUpdate = $true
                }
            }

            if($needsUpdate -eq $true) {
                $spField.Update()
                $ClientContext.ExecuteQuery()
                Write-Verbose "`t`tUpdated Field: $($Field.DisplayName)" -Verbose
            } else {
                Write-Verbose "`t`tDid not need to update Field: $($Field.DisplayName)"
            }
        }
        foreach($Field in $listxml.Fields.RemoveField) {
            Remove-ListField -List $SPList -FieldName $Field.Name -ClientContext $ClientContext
        }

        Write-Verbose "`tViews" -Verbose
        foreach ($view in $listxml.Views.View) {
            $spView = Get-ListView -List $SPList -ViewName $view.DisplayName -ClientContext $ClientContext
            if($spView -ne $null) {
            
                $Paged = [bool]::Parse($view.RowLimit.Paged)
                $DefaultView = [bool]::Parse($view.DefaultView)
                $RowLimit = $view.RowLimit.InnerText
                $Query = $view.Query.InnerXml.Replace(" xmlns=`"http://schemas.microsoft.com/sharepoint/`"", "")
                $ViewFields = $view.ViewFields.FieldRef | Select -ExpandProperty Name

                $spView = Update-ListView -List $splist -ViewName $view.DisplayName -Paged $Paged -Query $Query -RowLimit $RowLimit -DefaultView $DefaultView -ViewFields $ViewFields -ClientContext $ClientContext
                Write-Verbose "`t`tUpdated List View: $($view.DisplayName)" -Verbose
            } else {
            
                $Paged = [bool]::Parse($view.RowLimit.Paged)
                $PersonalView = [bool]::Parse($view.PersonalView)
                $DefaultView = [bool]::Parse($view.DefaultView)
                $RowLimit = $view.RowLimit.InnerText
                $Query = $view.Query.InnerXml.Replace(" xmlns=`"http://schemas.microsoft.com/sharepoint/`"", "")
                $ViewFields = $view.ViewFields.FieldRef | Select -ExpandProperty Name
                $ViewType = $view.Type
                $spView = New-ListView -List $splist -ViewName $view.DisplayName -Paged $Paged -PersonalView $PersonalView -Query $Query -RowLimit $RowLimit -DefaultView $DefaultView -ViewFields $ViewFields -ViewType $ViewType -ClientContext $ClientContext
                Write-Verbose "`t`tCreated List View: $($view.DisplayName)" -Verbose
            }
        }

        Write-Verbose "`tFiles and Folders" -Verbose
        if($listxml.DeleteItems) {
            foreach($itemXml in $listxml.DeleteItems.Item) {
                $item = Get-ListItem -itemUrl $itemXml.Url -Folder $itemXml.Folder -List $SPList -ClientContext $clientContext
                if($item -ne $null) {
                    Remove-ListItem -listItem $item -ClientContext $clientContext
                }
            }
        }
        if($listxml.UpdateItems) {
            foreach($itemXml in $listxml.UpdateItems.Item) {
                Update-ListItem -listItemXml $itemXml -List $SPList -ClientContext $clientContext 
            }
        }

        foreach($folderXml in $listxml.Folder) {
            Write-Verbose "`t`t$($folderXml.Url)" -Verbose
            $spFolder = Get-RootFolder -List $SPList -ClientContext $ClientContext
            Add-Files -Folder $spFolder -FolderXml $folderXml -ResourcesPath $ResourcesPath `
                -MinorVersionsEnabled $MinorVersionsEnabled -MajorVersionsEnabled $MajorVersionsEnabled -ContentApprovalEnabled $ContentApprovalEnabled `
                -ClientContext $clientContext -RemoteContext $RemoteContext 
        }

        Write-Verbose "`tPropertyBag Values" -Verbose
        foreach ($ProperyBagValueXml in $listxml.PropertyBag.PropertyBagValue) {
            $Indexable = $false
            if($ProperyBagValueXml.Indexable) {
                $Indexable = [bool]::Parse($ProperyBagValueXml.Indexable)
            }

            Set-PropertyBagValue -Key $ProperyBagValueXml.Key -Value $ProperyBagValueXml.Value -Indexable $Indexable -List $SPList -ClientContext $ClientContext
        }
        
        Write-Verbose "`tUpdating Other List Settings" -Verbose
        $listNeedsUpdate = $false
        
        if($listxml.ContentTypesEnabled) {
            $contentTypesEnabled = [bool]::Parse($listxml.ContentTypesEnabled )
            if($SPList.ContentTypesEnabled -ne $contentTypesEnabled) {
                $SPList.ContentTypesEnabled = $contentTypesEnabled
                Write-Verbose "`t`tUpdating ContentTypesEnabled"
                $listNeedsUpdate = $true
            }
        }
        if($listxml.Description) {
            $description = $listxml.Description
            if($SPList.Description -ne $description) {
                $SPList.Description = $description
                Write-Verbose "`t`tUpdating Description"
                $listNeedsUpdate = $true
            }
        }
        if($listxml.EnableAttachments) {
            $enableAttachments = [bool]::Parse($listxml.EnableAttachments  )
            if($SPList.EnableAttachments -ne $enableAttachments) {
                $SPList.EnableAttachments = $enableAttachments
                Write-Verbose "`t`tUpdating EnableAttachments"
                $listNeedsUpdate = $true
            }
        }
        if($listxml.EnableFolderCreation ) {
            $enableFolderCreation = [bool]::Parse($listxml.EnableFolderCreation  )
            if($SPList.EnableFolderCreation -ne $enableFolderCreation) {
                $SPList.EnableFolderCreation = $enableFolderCreation
                Write-Verbose "`t`tUpdating EnableFolderCreation"
                $listNeedsUpdate = $true
            }
        }
        if($listxml.EnableMinorVersions) {
            $enableMinorVersions = [bool]::Parse($listxml.EnableMinorVersions)
            if($SPList.EnableMinorVersions -ne $enableMinorVersions) {
                $SPList.EnableMinorVersions = $enableMinorVersions
                Write-Verbose "`t`tUpdating EnableMinorVersions"
                $listNeedsUpdate = $true
            }
        }
        if($listxml.EnableModeration) {
            $enableModeration = [bool]::Parse($listxml.EnableModeration)
            if($SPList.EnableModeration -ne $enableModeration) {
                $SPList.EnableModeration = $enableModeration
                Write-Verbose "`t`tUpdating EnableModeration"
                $listNeedsUpdate = $true
            }
        }
        if($listxml.EnableVersioning) {
            $enableVersioning = [bool]::Parse($listxml.EnableVersioning)
            if($SPList.EnableVersioning -ne $enableVersioning) {
                $SPList.EnableVersioning = $enableVersioning
                Write-Verbose "`t`tUpdating EnableVersioning"
                $listNeedsUpdate = $true
            }
        }
        if($listxml.ForceCheckout) {
            $forceCheckout = [bool]::Parse($listxml.ForceCheckout)
            if($SPList.ForceCheckout -ne $forceCheckout) {
                $SPList.ForceCheckout = $forceCheckout
                Write-Verbose "`t`tUpdating ForceCheckout"
                $listNeedsUpdate = $true
            }
        }
        if($listxml.Hidden) {
            $hidden = [bool]::Parse($listxml.Hidden)
            if($SPList.Hidden -ne $hidden) {
                $SPList.Hidden = $hidden
                Write-Verbose "`t`tUpdating Hidden"
                $listNeedsUpdate = $true
            }
        }
        <#
        if($listxml.OnQuickLaunchBar) {
            $onQuickLaunchBar = [bool]::Parse($listxml.OnQuickLaunchBar)
            if($SPList.OnQuickLaunch -ne $onQuickLaunchBar) {
                $SPList.OnQuickLaunch = $onQuickLaunchBar
                Write-Verbose "`t`tUpdating OnQuickLaunchBar"
                $listNeedsUpdate = $true
            }
        }
        #>
        if($listxml.NoCrawl) {
            $noCrawl = [bool]::Parse($listxml.NoCrawl)
            if($SPList.NoCrawl -ne $noCrawl) {
                $SPList.NoCrawl = $noCrawl
                Write-Verbose "`t`tUpdating NoCrawl"
                $listNeedsUpdate = $true
            }
        }

        if($listNeedsUpdate) {
            $SPList.Update()
            $ClientContext.Load($SPList)
            $ClientContext.ExecuteQuery()
            Write-Verbose "`t`tUpdated List Settings" -Verbose
        }
        $SPList
        
    }
    end{
    }
}