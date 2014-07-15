function Get-PublishingPage {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$pageUrl,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web]$web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$clientContext
    )
    process {
        Write-Verbose "Getting page $($pageUrl)" -Verbose
        $pagesLibrary = $web.Lists.GetByTitle("Pages")
        $camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
        $camlQuery.ViewXml = "<View><Query><Where><Eq><FieldRef Name='FileLeafRef' /><Value Type='Text'>$($pageUrl)</Value></Eq></Where></Query></View>"
        $items = $pagesLibrary.GetItems($camlQuery)
        $ClientContext.Load($items)
        $ClientContext.ExecuteQuery()
        
        $page = $null
        if($items.Count -gt 0) {
            $page = $items[0]
            $ClientContext.Load($page)
            $ClientContext.ExecuteQuery()
        }
        $page
    }
    end {
    }
}

function Remove-PublishingPage {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ListItem]$PublishingPage,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web]$Web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $PublishingPage.DeleteObject()
        $ClientContext.ExecuteQuery()
    }
    end{}
}

function New-PublishingPage {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][System.Xml.XmlElement]$PageXml,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web]$Web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        
        $pageAlreadyExists = $false
        $replaceContent = $false
        if($PageXml.ReplaceContent) {
            $replaceContent = [bool]::Parse($PageXml.ReplaceContent)
        }

        # Get List information
        $pagesList = $Web.Lists.GetByTitle("Pages")
		$clientContext.Load($pagesList)

        # Check for existing Page
		$existingPageCamlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
		$existingPageCamlQuery.ViewXml = "<View><Query><Where><Eq><FieldRef Name='FileLeafRef' /><Value Type='Text'>$($PageXml.Url)</Value></Eq></Where></Query></View>"
		$existingPageListItems = $pagesList.GetItems($existingPageCamlQuery)
		$clientContext.Load($existingPageListItems)

        # Get Page Layout
        Write-Verbose "Getting Page Layout $($PageXml.PageLayout) for new page" -Verbose
        $rootWeb = $ClientContext.Site.RootWeb
        $masterPageCatalog = $rootWeb.GetCatalog([Microsoft.SharePoint.Client.ListTemplateType]::MasterPageCatalog)
        $pageLayoutCamlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
        $pageLayoutCamlQuery.ViewXml = "<View><Query><Where><Eq><FieldRef Name='FileLeafRef' /><Value Type='Text'>$($PageXml.PageLayout)</Value></Eq></Where></Query></View>"
        $pageLayoutItems = $masterPageCatalog.GetItems($pageLayoutCamlQuery)
        $ClientContext.Load($pageLayoutItems)
 

        # Get Publishing Web
        $publishingWeb = [Microsoft.SharePoint.Client.Publishing.PublishingWeb]::GetPublishingWeb($ClientContext, $Web)
        $ClientContext.Load($publishingWeb)

        # Setup Complete, call server
		$clientContext.ExecuteQuery()

        $MajorVersionsEnabled = $pagesList.EnableVersioning
        $MinorVersionsEnabled = $pagesList.EnableMinorVersions
        $ContentApprovalEnabled = $pagesList.EnableModeration
        $CheckOutRequired = $pagesList.ForceCheckout
		
		if ($existingPageListItems.Count -ne 0)
		{
			Write-Verbose "Page $($PageXml.Url) already exists"
			$pageAlreadyExists = $true
			$originalPublishingPageListItem = $existingPageListItems[0]
		}
        
        if($pageAlreadyExists -and $replaceContent -eq $false) {
            Write-Verbose "Page $($PageXml.Url) already Exists and ReplaceContent is set to false" -Verbose
            return
        }
        
        # Load Page Layout Item if avilable
        if ($pageLayoutItems.Count -lt 1)
		{
			Write-Verbose "Missing Page Layout $($PageXml.PageLayout), Can not create $($PageXml.Url)" -Verbose
            return
		} else {
            $pageLayout = $pageLayoutItems[0]
            $ClientContext.Load($pageLayout)
            $ClientContext.ExecuteQuery()
        }

        # Rename existing page if needed
        if($pageAlreadyExists) {
            Write-Verbose "Renaming existing page"
            if($CheckOutRequired) {
                Write-Verbose "Checking-out existing page"
                $originalPublishingPageListItem.File.CheckOut()
            }
			$tempPageUrl = $PageXml.Url.Replace(".aspx", "-temp.aspx");
			$originalPublishingPageListItem["FileLeafRef"] = $tempPageUrl
			$originalPublishingPageListItem.Update()
            $ClientContext.ExecuteQuery()
            if($CheckOutRequired) {
                Write-Verbose "Checking-in existing page"
                $originalPublishingPageListItem.File.CheckIn("Draft Check-in", [Microsoft.SharePoint.Client.CheckinType]::MinorCheckIn)
                $ClientContext.ExecuteQuery()
            }
        }
       

        Write-Verbose "Creating page $($PageXml.Url) using layout $($PageXml.PageLayout)" -Verbose
        
        $publishingPageInformation = New-Object Microsoft.SharePoint.Client.Publishing.PublishingPageInformation
        $publishingPageInformation.Name = $PageXml.Url;
        $publishingPageInformation.PageLayoutListItem = $pageLayout

        $publishingPage = $publishingWeb.AddPublishingPage($publishingPageInformation)
        foreach($property in $PageXml.Property) {
            if($propertyXml.Type -and $propertyXml.Type -eq "TaxonomyField") {
                Write-Verbose "Setting TaxonomyField $($propertyXml.Name) to $($propertyXml.Value)"
                $field = $pagesList.Fields.GetByInternalNameOrTitle($propertyXml.Name)
                $taxField  = [SharePointClient.PSClientContext]::CastToTaxonomyField($clientContext, $field)

                if ($taxField.AllowMultipleValues) {
                    $taxFieldValueCol = New-Object Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValueCollection($clientContext, "", $taxField)
                    $taxFieldValueCol.PopulateFromLabelGuidPairs($propertyXml.Value)

                    $taxField.SetFieldValueByValueCollection($publishingPage.ListItem, $taxFieldValueCol);
                } else {
                    $publishingPage.ListItem[$propertyXml.Name] = $propertyXml.Value
                }

            } elseif ($property.Name -eq "ContentType") {
                // Do Nothing
            } else {
                $publishingPage.ListItem[$property.Name] = $property.Value
            }
        }
        $publishingPage.ListItem.Update()
        $publishingPageFile = $publishingPage.ListItem.File
        $ClientContext.load($publishingPage)
        $ClientContext.load($publishingPageFile)
        $ClientContext.ExecuteQuery()

        if($publishingPageFile.CheckOutType -ne [Microsoft.SharePoint.Client.CheckOutType]::None) {
            $publishingPageFile.CheckIn("Draft Check-in", [Microsoft.SharePoint.Client.CheckinType]::MinorCheckIn)
            $ClientContext.Load($publishingPageFile)
            $ClientContext.ExecuteQuery()
        }
        
        if($PageXml.Level -eq "Published"  -and $MinorVersionsEnabled -and $MajorVersionsEnabled) {
            $publishingPageFile.Publish("Publishing Page")
            $ClientContext.Load($publishingPageFile)
            $ClientContext.ExecuteQuery()
        }
        if($PageXml.Approval -eq "Approved" -and $ContentApprovalEnabled) {
            $publishingPageFile.Approve("Approving Page")
            $ClientContext.Load($publishingPageFile)
            $ClientContext.ExecuteQuery()
        }
        
        if($PageXml.WelcomePage) {
            $isWelcomePage = $false
            $isWelcomePage = [bool]::Parse($PageXml.WelcomePage)
            if($isWelcomePage) {
                Set-WelcomePage -WelcomePageUrl $publishingPageFile.ServerRelativeUrl -Web $Web -ClientContext $ClientContext
            }
        }

        # Delete orginal page
		if ($pageAlreadyExists)
		{
			$originalPublishingPageListItem.DeleteObject()
			$clientContext.ExecuteQuery()
		}
        
    }
}

function Delete-PublishingPage {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][System.Xml.XmlElement]$PageXml,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web]$Web,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {

		$pagesList = $Web.Lists.GetByTitle("Pages");
		$clientContext.Load($pagesList)
		$clientContext.ExecuteQuery()

		$camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery;
		$camlQuery.ViewXml = "<View><Query><Where><Eq><FieldRef Name='FileLeafRef' /><Value Type='Text'>{0}</Value></Eq></Where></Query></View>" -f $PageXml.Url

		$listItems = $pagesList.GetItems($camlQuery);

		$clientContext.Load($listItems)
		$clientContext.ExecuteQuery()

		if ($listItems.Count -ne 0)
		{
			$item = $listItems[0]
			$item.DeleteObject()
			$clientContext.ExecuteQuery()
		}
    }
}
