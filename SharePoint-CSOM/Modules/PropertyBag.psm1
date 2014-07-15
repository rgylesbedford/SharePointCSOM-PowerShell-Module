function Set-IndexableProperty {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)][string]$Key,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web]$Web,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $indexedPropertyBagKey = "vti_indexedpropertykeys"

        $oldIndexedValues = Get-PropertyBagValue -Key $indexedPropertyBagKey -Web $Web -ClientContext $ClientContext

        $keyBytes = [System.Text.Encoding]::Unicode.GetBytes($Key)
        $encodedKey = [Convert]::ToBase64String($keyBytes)
        
        if($oldIndexedValues -NotLike "*$encodedKey*") {
            $Web.AllProperties[$indexedPropertyBagKey] = "$oldIndexedValues$encodedKey|"
        }
    }
}
function Set-PropertyBagValue {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)][string]$Key,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)][string]$Value = $null,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)][bool]$Indexable = $false,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Site]$Site,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web]$Web,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Folder]$Folder,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $indexedPropertyBagKey = "vti_indexedpropertykeys"
        Write-Verbose "Set-PropertyBagValue Key: $Key Value: $Value Indexable: $Indexable" -Verbose
        if($Site) {

            if($Indexable) {
                $oldIndexedValues = Get-PropertyBagValue -Key $indexedPropertyBagKey -Site $Site -ClientContext $ClientContext

                $keyBytes = [System.Text.Encoding]::Unicode.GetBytes($Key)
                $encodedKey = [Convert]::ToBase64String($keyBytes)
        
                if($oldIndexedValues -NotLike "*$encodedKey*") {
                    $Site.RootWeb.AllProperties[$indexedPropertyBagKey] = "$oldIndexedValues$encodedKey|"
                }
            }


            $Site.RootWeb.AllProperties[$Key] = $Value
            $Site.RootWeb.Update()
            $ClientContext.Load($Site)
            $ClientContext.Load($Site.RootWeb)
            $ClientContext.Load($Site.RootWeb.AllProperties)
            $ClientContext.ExecuteQuery()

        } elseif($Web) {
            if($Indexable) {
                $oldIndexedValues = Get-PropertyBagValue -Key $indexedPropertyBagKey -Web $Web -ClientContext $ClientContext

                $keyBytes = [System.Text.Encoding]::Unicode.GetBytes($Key)
                $encodedKey = [Convert]::ToBase64String($keyBytes)
        
                if($oldIndexedValues -NotLike "*$encodedKey*") {
                    $Web.AllProperties[$indexedPropertyBagKey] = "$oldIndexedValues$encodedKey|"
                }
            }

            $Web.AllProperties[$Key] = $Value
            $Web.Update()
            $ClientContext.Load($Web)
            $ClientContext.Load($Web.AllProperties)
            $ClientContext.ExecuteQuery()

        } elseif($List) {
            if($Indexable) {
                $oldIndexedValues = Get-PropertyBagValue -Key $indexedPropertyBagKey -List $List -ClientContext $ClientContext

                $keyBytes = [System.Text.Encoding]::Unicode.GetBytes($Key)
                $encodedKey = [Convert]::ToBase64String($keyBytes)
        
                if($oldIndexedValues -NotLike "*$encodedKey*") {
                    $List.RootFolder.Properties[$indexedPropertyBagKey] = "$oldIndexedValues$encodedKey|"
                }
            }
            $List.RootFolder.Properties[$Key] = $Value
            $List.RootFolder.Update()
            $List.Update()
            $ClientContext.Load($List)
            $ClientContext.Load($List.RootFolder)
            $ClientContext.Load($List.RootFolder.Properties)
            $ClientContext.ExecuteQuery()

        } elseif($Folder) {
            if($Indexable) {
                $oldIndexedValues = Get-PropertyBagValue -Key $indexedPropertyBagKey -Folder $Folder -ClientContext $ClientContext

                $keyBytes = [System.Text.Encoding]::Unicode.GetBytes($Key)
                $encodedKey = [Convert]::ToBase64String($keyBytes)
        
                if($oldIndexedValues -NotLike "*$encodedKey*") {
                    $Folder.Properties[$indexedPropertyBagKey] = "$oldIndexedValues$encodedKey|"
                }
            }
            $Folder.Properties[$Key] = $Value
            $Folder.Update()
            $ClientContext.Load($Folder)
            $ClientContext.Load($Folder.Properties)
            $ClientContext.ExecuteQuery()

        } else {
            return $null
        }
    }
}
function Remove-PropertyBagValue {
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)][string]$Key,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Site]$Site,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web]$Web,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Folder]$Folder,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        if($Site) {

            $Site.RootWeb.AllProperties[$Key] = ""
            $Site.RootWeb.Update()
            $ClientContext.Load($Site)
            $ClientContext.ExecuteQuery()

        } elseif($Web) {
            $Web.AllProperties[$Key] = ""
            $Web.Update()
            $ClientContext.Load($Web)
            $ClientContext.ExecuteQuery()

        } elseif($List) {

            $List.RootFolder.Properties[$Key] = ""
            $List.RootFolder.Update()
            $ClientContext.Load($List)
            $ClientContext.ExecuteQuery()

        } elseif($Folder) {

            $Folder.Properties[$Key] = ""
            $Folder.Update()
            $ClientContext.Load($Folder)
            $ClientContext.ExecuteQuery()

        } else {
            return $null
        }
    }
}
function Get-PropertyBagValue {
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)][string]$Key,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Site]$Site,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web]$Web,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Folder]$Folder,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $value = ""

        if($Site) {
            $ClientContext.Load($Site)
            $ClientContext.ExecuteQuery()
            $properties = $Site.RootWeb.AllProperties 
        } elseif($Web) {
            $ClientContext.Load($Web)
            $ClientContext.ExecuteQuery()
            $properties = $Web.AllProperties
        } elseif($List) {
            $ClientContext.Load($List)
            $ClientContext.ExecuteQuery()
            $properties = $List.RootFolder.Properties
        } elseif($Folder) {
            $ClientContext.Load($Folder)
            $ClientContext.ExecuteQuery()
            $properties = $Folder.Properties
        } else {
            return $value 
        }


        $ClientContext.Load($properties)
        $ClientContext.ExecuteQuery()

        $fieldValue = $properties.FieldValues[$Key]
        
        if($fieldValue -ne $null) {
            $value = $fieldValue.ToString()
        }
        $value
    }
}


function Set-PropertyBagMetadataValues {
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)][Hashtable]$Properties,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)][Hashtable]$MetadataSingleFields,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)][Hashtable]$MetadataMultiFields,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$MetadataList,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)][bool]$Indexable = $false,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Site]$Site,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web]$Web,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Folder]$Folder,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$MetadataListClientContext
         
    )
    process {
        if (!$MetadataListClientContext) {
            $MetadataListClientContext = $ClientContext
        }

        $metadataMultiValues = {}.Invoke()
        $metadataSingleValues = {}.Invoke()

        foreach($property in $Properties.GetEnumerator()) {
            $key = $property.Key
            $value = $property.Value
            if ($MetadataMultiFields.ContainsKey($key)) {
                $metadataMultiValues.Add($property)
            } Elseif ($MetadataSingleFields.ContainsKey($key)) {
                $metadataSingleValues.Add($property)
            } else {
                 Set-PropertyBagValue -Key $key -Value $value -Indexable $true -Web $Web -ClientContext $clientContext
            }
           
        }

        $xml = [xml]@"
<Item>
<Property Name="Title"  Value="Test item"/>
</Item>
"@


        foreach($property in $metadataMultiValues) {
            $prop = $xml.CreateElement('Property')
            $prop.SetAttribute('Name', $MetadataMultiFields[$property.Key])
            $prop.SetAttribute('Type', 'TaxonomyField')
            $prop.SetAttribute('Value', $property.Value)
            $xml.Item.AppendChild($prop)
        }

        foreach($property in $metadataSingleValues) {
            $prop = $xml.CreateElement('Property')
            $prop.SetAttribute('Name', $MetadataSingleFields[$property.Key])
            $prop.SetAttribute('Type', 'TaxonomyField')
            $prop.SetAttribute('Value', $property.Value)
            $xml.Item.AppendChild($prop)
        }
        Write-Output $xml.OuterXml
        $item = New-ListItem $xml.Item $MetadataList $MetadataListClientContext

        foreach($property in $metadataMultiValues) {
            $fieldValue = $item[$MetadataMultiFields[$property.Key]] 
            $propertyBagKeyPrefix = $property.Key
            $propertyBagValue = ""
            $propertyBagKeySuffix = "00"
            $propertyBagKeyTaxSuffix = "ID"
            $propertyBagKeySearchSuffix = "Search"
            $count = 0
            $maxCount = 9
            foreach($term in $fieldValue) {
                $propertyBagKey = $propertyBagKeyPrefix + $count.ToString().PadLeft(2,"0")
                Set-PropertyBagValue -Key $propertyBagKey -Value $term.Label -Indexable $true -Web $web -ClientContext $ClientContext
                $propertyBagValue += [string]::Format("{0};#{1}|{2};#", $term.WssId, $term.Label, $term.TermGuid)
                $count++
            }
            for($count; $count -le $maxCount; $count++) {
                $propertyBagKey = $propertyBagKeyPrefix + $count.ToString().PadLeft(2,"0")
                Set-PropertyBagValue -Key $propertyBagKey -Indexable $true -Web $web -ClientContext $ClientContext
            }
            # set old key to no value
            Set-PropertyBagValue -Key $propertyBagKeyPrefix -Indexable $true -Web $web -ClientContext $ClientContext
            if($propertyBagValue -ne "") {
                
                $propertyBagValue = $propertyBagValue.Substring(0,$propertyBagValue.Length-2) # remove trailing ;#
                $propertyBagKey = "$propertyBagKeyPrefix$propertyBagKeyTaxSuffix" 
                Set-PropertyBagValue -Key $propertyBagKey -Value $propertyBagValue -Indexable $true -Web $web -ClientContext $ClientContext
                

                $propertyBagSearchValues = ""
                foreach($term in $fieldValue) {

                    $propertyBagSearchValues += [string]::Format("#0{0} ",$term.TermGuid)
                    
                }
                $propertyBagSearchValues = $propertyBagSearchValues.Substring(0,$propertyBagSearchValues.Length-1) # remove trailing space
                $propertyBagKey = "$propertyBagKeyPrefix$propertyBagKeySearchSuffix"
                Set-PropertyBagValue -Key $propertyBagKey -Value $propertyBagSearchValues -Indexable $true -Web $web -ClientContext $ClientContext
            }


        }

        foreach($property in $metadataSingleValues) {
            $fieldValue = $item[$MetadataSingleFields[$property.Key]] 
            $propertyBagKeyPrefix = $property.Key
            $propertyBagValue = ""
            $propertyBagKeySuffix = "00"
            $propertyBagKeyTaxSuffix = "ID"
            $propertyBagKey = $propertyBagKeyPrefix

            $propertyBagKey = "$propertyBagKeyPrefix$propertyBagKeyTaxSuffix"
            if ($fieldValue) {
                Set-PropertyBagValue -Key $propertyBagKeyPrefix -Value $fieldValue.Label -Indexable $true -Web $web -ClientContext $ClientContext
                $propertyBagValue = [string]::Format("{0};#{1}|{2}", $fieldValue.WssId, $fieldValue.Label, $fieldValue.TermGuid)
                Set-PropertyBagValue -Key $propertyBagKey -Value $propertyBagValue -Indexable $true -Web $web -ClientContext $ClientContext

            } else {
                Set-PropertyBagValue -Key $propertyBagKeyPrefix -Indexable $true -Web $web -ClientContext $ClientContext
                Set-PropertyBagValue -Key $propertyBagKey -Value $propertyBagValue -Indexable $true -Web $web -ClientContext $ClientContext
            }
        }


        #Remove-ListItem $item $ClientContext

    }
}