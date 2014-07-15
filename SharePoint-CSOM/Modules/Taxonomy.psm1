
# The taxonomy code is untested

function Get-TaxonomySession {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $session = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($ClientContext)
        $session.UpdateCache()
        $session
    }
}
function Get-DefaultSiteCollectionTermStore {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]$TaxonomySession,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $store = $TaxonomySession.GetDefaultSiteCollectionTermStore()
        $ClientContext.Load($store)
        $ClientContext.ExecuteQuery()
        $store
    }
}

function Get-TermGroup {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$GroupName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Taxonomy.TermStore]$TermStore,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $group = $TermStore.Groups.GetByName($GroupName)
        $ClientContext.Load($group)
        $ClientContext.ExecuteQuery()
        $group
    }
}
function Add-TermGroup {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Name,
        [parameter(ValueFromPipelineByPropertyName = $true)][guid]$Id = [guid]::NewGuid(),
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Taxonomy.TermStore]$TermStore,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $group = $TermStore.CreateGroup($Name,$Id)
        $TermStore.CommitAll()
        $ClientContext.load($group)
        $ClientContext.ExecuteQuery()
        $group
    }
}

function Get-TermSet {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$SetName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Taxonomy.TermGroup]$TermGroup,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $termSet = $TermGroup.TermSets.GetByName($SetName)
        $ClientContext.Load($termSet)
        $ClientContext.ExecuteQuery()
        $termSet
    }
}
function Add-TermSet {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Name,
        [parameter(ValueFromPipelineByPropertyName = $true)][int]$Language = 1033,
        [parameter(ValueFromPipelineByPropertyName = $true)][guid]$Id = [guid]::NewGuid(),
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Taxonomy.TermGroup]$TermGroup,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $termSet = $TermGroup.CreateTermSet($Name, $Id, $Language)
        $TermGroup.TermStore.CommitAll()
        $ClientContext.load($termSet)
        $ClientContext.ExecuteQuery()
        $termSet
    }
}
function Add-Term {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName = "Name")][string]$Name,
        [parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "Language")][int]$Language = 1033,
        [parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "Id")][guid]$Id = [guid]::NewGuid(),
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Taxonomy.TermSet]$TermSet,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $term = $TermSet.CreateTerm($Name, $Language, $Id)

        $TermSet.TermStore.CommitAll()
        $ClientContext.load($term)
        $ClientContext.ExecuteQuery()
        $term
    }
}
function Get-Term {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][guid]$Id,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Taxonomy.TermSet]$TermSet,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $term = $TermSet.GetTerm($Id)
        $ClientContext.Load($term)
        $ClientContext.ExecuteQuery()
        $term
    }
}
function Get-Terms {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Taxonomy.TermSet]$TermSet,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $terms = $TermSet.Terms
        $ClientContext.Load($terms)
        $ClientContext.ExecuteQuery()
        $terms
    }
}
function Get-ChildTerms {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Taxonomy.Term]$Term,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $terms = $Term.Terms
        $ClientContext.Load($terms)
        $ClientContext.ExecuteQuery()
        $terms
    }
}

function Get-TermsByName {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Name,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Taxonomy.TermSet]$TermSet,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $LabelMatchInformation = New-Object Microsoft.SharePoint.Client.Taxonomy.LabelMatchInformation($ClientContext);
        $LabelMatchInformation.Lcid = 1033
        $LabelMatchInformation.TrimUnavailable = $false         
        $LabelMatchInformation.TermLabel = $Name

        $terms = $TermSet.GetTerms($LabelMatchInformation)
        $ClientContext.Load($terms)
        $ClientContext.ExecuteQuery()
        $terms
    }
}

function Add-ChildTerm {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Name,
        [parameter(ValueFromPipelineByPropertyName = $true)][int]$Language = 1033,
        [parameter(ValueFromPipelineByPropertyName = $true)][guid]$Id = [guid]::NewGuid(),
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.Taxonomy.Term]$parentTerm,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][Microsoft.SharePoint.Client.ClientContext]$ClientContext
    )
    process {
        $term = $parentTerm.CreateTerm($Name, $Language, $Id)

        $parentTerm.TermStore.CommitAll()
        $ClientContext.load($term)
        $ClientContext.ExecuteQuery()
        $term
    }
}