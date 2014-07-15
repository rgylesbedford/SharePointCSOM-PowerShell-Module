function Add-Feature {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][guid]$FeatureId,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][bool]$fromSandboxSolution = $false,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][bool]$force = $false,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.FeatureCollection] $Features,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $FeatureDefinitionScope = [Microsoft.SharePoint.Client.FeatureDefinitionScope]::Farm
        if($fromSandboxSolution) {
            $FeatureDefinitionScope = [Microsoft.SharePoint.Client.FeatureDefinitionScope]::Site
        }
        $feature = $features | Where {$_.DefinitionId -eq $FeatureId}
        if($feature -eq $null) {
            $Features.Add($FeatureId, $force, $FeatureDefinitionScope)
            $ClientContext.ExecuteQuery()
            Write-Verbose "Activating Feature $FeatureId" -Verbose
        }
    }
}
function Remove-Feature {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][guid]$FeatureId,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][bool]$force = $false,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.FeatureCollection] $Features,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $feature = $features | Where {$_.DefinitionId -eq $FeatureId}
        if($feature) {
            $features.Remove($featureId, $force)
            $ClientContext.ExecuteQuery()
             Write-Verbose "Deactivating Feature $FeatureId" -Verbose
        }
    }
}
function Add-Features {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][System.Xml.XmlElement]$FeaturesXml,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Site] $site, 
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        if($web) {
            $features = $web.Features
        } elseif($site) {
            $features = $site.Features
        }
        $ClientContext.Load($features)
        $ClientContext.ExecuteQuery()
        foreach($featureXml in $FeaturesXml.Feature) {
            $featureId = [guid] $featureXml.FeatureID
            $force = $false
            if($featureXml.Force) {
                $force = [bool]::Parse($featureXml.Force)
            }
            $SandboxSolution = $false
            if($featureXml.SandboxSolution) {
                $SandboxSolution = [bool]::Parse($featureXml.SandboxSolution)
            }
            Add-Feature -featureId $featureId -force $force -fromSandboxSolution $SandboxSolution -features $features -ClientContext $ClientContext
        }
    }
}
function Remove-Features {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][System.Xml.XmlElement]$FeaturesXml,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Web] $web,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Site] $site, 
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        if($web) {
            $features = $web.Features
        } elseif($site) {
            $features = $site.Features
        }
        $ClientContext.Load($features)
        $ClientContext.ExecuteQuery()

        foreach($featureXml in $FeaturesXml.Feature) {
            $featureId = [guid] $featureXml.FeatureID
            $force = $false
            if($featureXml.Force) {
                $force = [bool]::Parse($featureXml.Force)
            }
            
            $feature = $features | Where {$_.DefinitionId -eq $FeatureId}
            if($feature) {
                $features.Remove($featureId, $force)
            }
            $ClientContext.ExecuteQuery()
        }
    }
}