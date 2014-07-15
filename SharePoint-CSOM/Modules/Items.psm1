function New-ListItem {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][System.Xml.XmlElement]$listItemXml,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List] $list,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    begin {
    }
    process {
        $listItemCreationInformation = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation 
        $newItem = $list.AddItem($listItemCreationInformation);
        Write-Verbose "Creating List Item"
        foreach($propertyXml in $listItemXml.Property) {
            if($propertyXml.Type -and $propertyXml.Type -eq "TaxonomyField") {
                Write-Verbose "Setting TaxonomyField $($propertyXml.Name) to $($propertyXml.Value)"
                $field = $list.Fields.GetByInternalNameOrTitle($propertyXml.Name)
                $taxField  = [SharePointClient.PSClientContext]::CastToTaxonomyField($clientContext, $field)

                if ($taxField.AllowMultipleValues) {
                    $taxFieldValueCol = New-Object Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValueCollection($clientContext, "", $taxField)
                    $taxFieldValueCol.PopulateFromLabelGuidPairs($propertyXml.Value)

                    $taxField.SetFieldValueByValueCollection($newItem, $taxFieldValueCol);
                } else {
                    $newItem[$propertyXml.Name] = $propertyXml.Value
                }

            } else {
                Write-Verbose "Setting Field $($propertyXml.Name) to $($propertyXml.Value)"
                $newItem[$propertyXml.Name] = $propertyXml.Value
            }
        }
        $newItem.Update();
        $clientContext.Load($newItem)
        $clientContext.ExecuteQuery()
        Write-Verbose "Created List Item"
        $newItem
    }
    end {
    }
}
function Add-ListItems {
[cmdletbinding()]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][System.Xml.XmlElement]$ItemsXml,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List] $list,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    begin {
    }
    process {
        $listItemCreationInformation = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation 
        $newItem = $list.AddItem($listItemCreationInformation);
        Write-Verbose "Creating List Item"
        foreach($propertyXml in $listItemXml.Property) {
            if($propertyXml.Type -and $propertyXml.Type -eq "TaxonomyField") {
                Write-Verbose "Setting TaxonomyField $($propertyXml.Name) to $($propertyXml.Value)"
                $field = $list.Fields.GetByInternalNameOrTitle($propertyXml.Name)
                $taxField  = [SharePointClient.PSClientContext]::CastToTaxonomyField($clientContext, $field)
                $taxFieldValueCol = New-Object Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValueCollection($clientContext, "", $taxField)
                $taxFieldValueCol.PopulateFromLabelGuidPairs($propertyXml.Value)
                $taxField.SetFieldValueByValueCollection($newItem, $taxFieldValueCol);
            } else {
                Write-Verbose "Setting Field $($propertyXml.Name) to $($propertyXml.Value)"
                $newItem[$propertyXml.Name] = $propertyXml.Value
            }
        }
        $newItem.Update();
        $clientContext.Load($newItem)
        $clientContext.ExecuteQuery()
        Write-Verbose "Created List Item"
        $newItem
    }
    end {
    }
}
function Get-ListItem {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$itemUrl,
        [parameter(Mandatory=$false, ValueFromPipeline=$true)][string]$folder = $null,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$list,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$clientContext
    )
    process {
        $camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
        $camlQuery.ViewXml = "<View><Query><Where><Eq><FieldRef Name='FileLeafRef' /><Value Type='Text'>$($itemUrl)</Value></Eq></Where></Query></View>"
        if($folder) {
            $clientContext.Load($list.RootFolder)
            $clientContext.ExecuteQuery()
            $camlQuery.FolderServerRelativeUrl = "$($list.RootFolder.ServerRelativeUrl)/$($folder)"
            Write-Verbose "CamlQuery FolderServerRelativeUrl: $($camlQuery.FolderServerRelativeUrl)" -Verbose
        }
        $items = $list.GetItems($camlQuery)
        $clientContext.Load($items)
        $clientContext.ExecuteQuery()
        
        $item = $null
        if($items.Count -gt 0) {
            $item = $items[0]
            $clientContext.Load($item)
            $clientContext.ExecuteQuery()
        }
        $item
    }
    end {
    }
}
function Update-ListItem {
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][System.Xml.XmlElement]$listItemXml,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$list,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$clientContext
    )
    process {
        $camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
        $camlQuery.ViewXml = "<View><Query><Where><Eq><FieldRef Name='FileLeafRef' /><Value Type='Text'>$($listItemXml.Url)</Value></Eq></Where></Query></View>"
        if($listItemXml.folder) {
            $clientContext.Load($list.RootFolder)
            $clientContext.ExecuteQuery()
            $camlQuery.FolderServerRelativeUrl = "$($list.RootFolder.ServerRelativeUrl)/$($listItemXml.folder)"
            Write-Verbose "CamlQuery FolderServerRelativeUrl: $($camlQuery.FolderServerRelativeUrl)" -Verbose
        }
        $items = $list.GetItems($camlQuery)
        $clientContext.Load($items)
        $clientContext.ExecuteQuery()
        
        $item = $null
        if($items.Count -gt 0) {
            $item = $items[0]
            $clientContext.Load($list)
            $clientContext.Load($item)
            $clientContext.Load($item.File)
            $clientContext.Load($list.Fields)
            $clientContext.ExecuteQuery()
        }
        if($item -ne $null) {

            $MajorVersionsEnabled = $list.EnableVersioning
            $MinorVersionsEnabled = $list.EnableMinorVersions
            $ContentApprovalEnabled = $list.EnableModeration
            $CheckOutRequired = $list.ForceCheckout

            if($CheckOutRequired) {
                Write-Verbose "Checking-out item"
                $item.File.CheckOut()
            }

            foreach($propertyXml in $listItemXml.Property) {
                if($propertyXml.Type -and $propertyXml.Type -eq "TaxonomyField") {
                    Write-Verbose "Setting TaxonomyField $($propertyXml.Name) to $($propertyXml.Value)"
                    $field = $list.Fields.GetByInternalNameOrTitle($propertyXml.Name)
                    $taxField  = [SharePointClient.PSClientContext]::CastToTaxonomyField($clientContext, $field)
                    $taxFieldValueCol = New-Object Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValueCollection($clientContext, "", $taxField)
                    $taxFieldValueCol.PopulateFromLabelGuidPairs($propertyXml.Value)
                    $taxField.SetFieldValueByValueCollection($item, $taxFieldValueCol);
                } else {
                    Write-Verbose "Setting Field $($propertyXml.Name) to $($propertyXml.Value)"
                    $item[$propertyXml.Name] = $propertyXml.Value
                }
            }

            $item.Update()
            $ClientContext.load($item)
            $ClientContext.ExecuteQuery()

            $ClientContext.load($item.File)
            $ClientContext.ExecuteQuery()

            if($item.File.CheckOutType -ne [Microsoft.SharePoint.Client.CheckOutType]::None) {
                if($MinorVersionsEnabled) {
                    $item.File.CheckIn("Draft Check-in", [Microsoft.SharePoint.Client.CheckinType]::MinorCheckIn)
                } else {
                    $item.File.CheckIn("Check-in", [Microsoft.SharePoint.Client.CheckinType]::MajorCheckIn)
                }
                $ClientContext.Load($item)
                $ClientContext.load($item.File)
                $ClientContext.ExecuteQuery()
            }
        
            if($listItemXml.Level -eq "Published" -and $MinorVersionsEnabled -and $MajorVersionsEnabled) {
                $item.File.Publish("Publishing Item")
                $ClientContext.Load($item)
                $ClientContext.ExecuteQuery()
            }
        }
    }
    end {
    }
}
function Remove-ListItem {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ListItem] $listItem, 
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext] $ClientContext
    )
    process {
        if($listItem -ne $null) {
            $listItem.DeleteObject()
            $ClientContext.ExecuteQuery()
            Write-Verbose "Deleted List Item"
        }
    }
}