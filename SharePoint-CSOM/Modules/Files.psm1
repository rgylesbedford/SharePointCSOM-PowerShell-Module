function Get-ResourceFile {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$FilePath,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ResourcesPath,
        [parameter(Mandatory=$false, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$RemoteContext
    )
    process {
        $file = $null
        if ($RemoteContext) {
            $fileURL = $resourcesPath+"/"+$filePath.Replace('\', '/')
            $web = $RemoteContext.Web
            $file = $web.GetFileByServerRelativeUrl($fileURL)

            $data = $file.OpenBinaryStream();
            $RemoteContext.Load($file)
            $RemoteContext.ExecuteQuery()
            
            $memStream = New-Object System.IO.MemoryStream
            $data.Value.CopyTo($memStream)
            $file = $memStream.ToArray()

        } else {
             $file = Get-Content -Encoding byte -Path "$resourcesPath\$filePath"
        }
        $file
    }
}

function Get-XMLFile {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$FilePath,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ConfigPath,
        [parameter(Mandatory=$false, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$RemoteContext
    )
    process {
        $xml = New-Object XML
        if ($RemoteContext) {
            $fileURL = $configPath+"/"+$filePath.Replace('\', '/')
            $web = $RemoteContext.Web
            $file = $web.GetFileByServerRelativeUrl($fileURL)

            $data = $file.OpenBinaryStream();
            $RemoteContext.Load($file)
            $RemoteContext.ExecuteQuery()

            [System.IO.Stream]$stream = $data.Value

            $xml.load($stream);
        } else {
            $xml.load("$configPath\$filePath");
        }
        $xml

    }
}


function Upload-File {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Folder]$Folder,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][System.Xml.XmlElement]$FileXml,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ResourcesPath,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext,
        [parameter(Mandatory=$false, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$RemoteContext,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)][bool] $MinorVersionsEnabled = $false,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)][bool] $MajorVersionsEnabled = $false,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)][bool] $ContentApprovalEnabled = $false,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)][bool] $CheckOutRequired = $false
    )
    process {
        
        $folderServerRelativeUrl = $Folder.ServerRelativeUrl
		$fileRelativeUrl = $folderServerRelativeUrl + "/" + $FileXml.Url
        Write-Verbose "$($fileRelativeUrl)" -Verbose

		#get file and check it out if necessary
		if ($CheckOutRequired) {
			try {
				#Write-Verbose "`tFile check-out..." -Verbose
				$file = $ClientContext.web.GetFileByServerRelativeUrl($fileRelativeUrl)
				$file.CheckOut()
				$ClientContext.Load($file)
				$ClientContext.ExecuteQuery()
			}
			catch {
				#Write-Verbose "File not found, could not check it out before uploading." -Verbose
			}
		}

        $fileCreationInformation = New-Object Microsoft.SharePoint.Client.FileCreationInformation
        $fileCreationInformation.Url = "$($fileRelativeUrl)"
        $fileCreationInformation.Content = Get-ResourceFile -FilePath $FileXml.Path -ResourcesPath $ResourcesPath -RemoteContext $RemoteContext
        if($FileXml.ReplaceContent) {
            $replaceContent = $false
            $replaceContent = [bool]::Parse($FileXml.ReplaceContent)
            $fileCreationInformation.Overwrite = $replaceContent
        }
        
        
        $file = $Folder.Files.Add($fileCreationInformation)
        foreach($property in $FileXml.Property) {
            $property.Value = $property.Value -replace "~folderUrl", $folderServerRelativeUrl
            if($property.Name -ne "ContentType") {
                $file.ListItemAllFields[$property.Name] = $property.Value
            }
        }
        $file.ListItemAllFields.Update()
        $ClientContext.load($file)
        $ClientContext.ExecuteQuery()

        if($file.CheckOutType -ne [Microsoft.SharePoint.Client.CheckOutType]::None) {
			#Write-Verbose "`tFile check-in..." -Verbose
            $file.CheckIn("Check-in file", [Microsoft.SharePoint.Client.CheckinType]::MinorCheckIn)
            $ClientContext.Load($file)
            $ClientContext.ExecuteQuery()
        }

        if($FileXml.Level -eq "Published" -and $MinorVersionsEnabled -and $MajorVersionsEnabled) {
			#Write-Verbose "`tPublishing..." -Verbose
            $file.Publish("Publishing file")
            $ClientContext.Load($file)
            $ClientContext.ExecuteQuery()
           # $file.CheckIn("Publishing File", [Microsoft.SharePoint.Client.CheckinType]::MajorCheckIn)
        }

        if($FileXml.Approval -eq "Approved" -and $ContentApprovalEnabled) {
			#Write-Verbose "`tApproving..." -Verbose
            $file.Approve("Approving file")
            $ClientContext.ExecuteQuery()
        }
        
        $file
    }
}
function Add-Files {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Folder]$Folder,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][System.Xml.XmlElement]$FolderXml,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ResourcesPath,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext,
        [parameter(Mandatory=$false, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$RemoteContext,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)][bool] $MinorVersionsEnabled = $false,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)][bool] $MajorVersionsEnabled = $false,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)][bool] $ContentApprovalEnabled = $false,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)][bool] $CheckOutRequired = $false
    )
    process {
        Write-Verbose "$($folderXml.Path)" -Verbose

        foreach($fileXml in $FolderXml.File) {
            Write-Verbose "$($fileXml.Path)"
            $file = Upload-File -Folder $Folder -FileXml $fileXml -ResourcesPath $ResourcesPath `
                        -MinorVersionsEnabled $MinorVersionsEnabled -MajorVersionsEnabled $MajorVersionsEnabled -ContentApprovalEnabled $ContentApprovalEnabled `
                        -ClientContext $clientContext -RemoteContext $RemoteContext -CheckOutRequired $CheckOutRequired
        }

        foreach ($ProperyBagValue in $folderXml.PropertyBag.PropertyBagValue) {
            $Indexable = $false
            if($PropertyBagValue.Indexable) {
                $Indexable = [bool]::Parse($PropertyBagValue.Indexable)
            }

            Set-PropertyBagValue -Key $ProperyBagValue.Key -Value $ProperyBagValue.Value -Indexable $Indexable -Folder $Folder -ClientContext $ClientContext
        }

        foreach($childfolderXml in $FolderXml.Folder) {
            $childFolder = Get-Folder -Folder $Folder -Name $childfolderXml.Url -ClientContext $clientContext
            if($childFolder -eq $null) {
                $childFolder = $Folder.Folders.Add($childfolderXml.Url)
                $ClientContext.Load($childFolder)
                $ClientContext.ExecuteQuery()
            }
            Add-Files -Folder $childFolder -FolderXml $childfolderXml -ResourcesPath $ResourcesPath `
                -MinorVersionsEnabled $MinorVersionsEnabled -MajorVersionsEnabled $MajorVersionsEnabled -ContentApprovalEnabled $ContentApprovalEnabled `
                -ClientContext $clientContext -RemoteContext $RemoteContext -CheckOutRequired $CheckOutRequired
        }
    }
}

function Get-RootFolder {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.List]$List,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $ClientContext.Load($List.RootFolder)
        $ClientContext.ExecuteQuery()
        $List.RootFolder
    }
}
function Get-Folder {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Folder]$Folder,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Name,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $folderToReturn = $null
        $ClientContext.Load($Folder.Folders)
        $ClientContext.ExecuteQuery()
        $folderToReturn = $Folder.Folders | Where {$_.Name -eq $Name}

        if($folderToReturn -ne $null) {
            $ClientContext.Load($folderToReturn)
            $ClientContext.ExecuteQuery()
        }

        $folderToReturn
    }
}

function Delete-File {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$ServerRelativeUrl,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $file = $ClientContext.Web.GetFileByServerRelativeUrl($ServerRelativeUrl)
        $ClientContext.Load($file)
        $file.DeleteObject()
        $ClientContext.ExecuteQuery()
    }
}

