function Get-AzDevOpsGitCommitList
{
    <#
    .SYNOPSIS
    Returns a list of Azure DevOps git commits.
    
    .DESCRIPTION
    Returns a list of Azure DevOps git commits based on a repository id. 
    The repository id can be returned with Get-AzDevOpsRepositoryList.
    
    .PARAMETER Instance
    The Team Services account or TFS server.
    
    .PARAMETER Collection
    For Azure DevOps the value for collection should be the name of your orginization. 
    For both Team Services and TFS The value should be DefaultCollection unless another collection has been created.
    
    .PARAMETER Project
    Project ID or project name.
    
    .PARAMETER ApiVersion
    Version of the api to use.
    
    .PARAMETER PersonalAccessToken
    Personal access token used to authenticate that has been converted to a secure string. 
    It is recomended to uses an Azure DevOps session to pass the personal access token parameter among funcitons, See New-AzDevOpsSession.
    https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=vsts
    
    .PARAMETER Credential
    Specifies a user account that has permission to send the request.
    
    .PARAMETER Proxy
    Use a proxy server for the request, rather than connecting directly to the Internet resource. Enter the URI of a network proxy server.
    
    .PARAMETER ProxyCredential
    Specifie a user account that has permission to use the proxy server that is specified by the -Proxy parameter. The default is the current user.
    
    .PARAMETER Session
    Azure DevOps PS session, created by New-AzDevOpsSession.
    
    .PARAMETER RepositoryId
    Id of the repository.

    .PARAMETER SearchCriteria_Author
    If set, search for commits that where created by this identity.

    .PARAMETER SearchCriteria_FromDate
    If provided, only include history entries created after this date.

    .PARAMETER SearchCriteria_ToDate
    If provided, only include history entries created before this date.

    .PARAMETER Skip
    The number of pull requests to ignore. For example, to retrieve results 101-150, set top to 50 and skip to 100.
    
    .PARAMETER Top
    Only return the top number of commits.
    
    .INPUTS
    None, does not support pipeline.
    
    .OUTPUTS
    PSObject, Azure Pipelines pipeline(s)
    
    .EXAMPLE
    Returns a list of Azure Pipelines git commits for 'myFirstProject' with the repository id of 7.
    Get-AzDevOpsPipelineList -Instance 'https://dev.azure.com' -Collection 'myCollection' -Project 'myFirstProject' -RepositoryId 7
    
    .LINK
    https://docs.microsoft.com/en-us/rest/api/azure/devops/git/commits/get%20commits?view=azure-devops-rest-6.0
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByPersonalAccessToken')]
    Param
    (
        [Parameter(Mandatory,
            ParameterSetName = 'ByPersonalAccessToken')]
        [Parameter(Mandatory,
            ParameterSetName = 'ByCredential')]
        [uri]
        $Instance,

        [Parameter(Mandatory,
            ParameterSetName = 'ByPersonalAccessToken')]
        [Parameter(Mandatory,
            ParameterSetName = 'ByCredential')]
        [string]
        $Collection,

        [Parameter(Mandatory,
            ParameterSetName = 'ByPersonalAccessToken')]
        [Parameter(Mandatory,
            ParameterSetName = 'ByCredential')]
        [string]
        $ApiVersion,

        [Parameter(ParameterSetName = 'ByPersonalAccessToken')]
        [Security.SecureString]
        $PersonalAccessToken,

        [Parameter(ParameterSetName = 'ByCredential')]
        [pscredential]
        $Credential,

        [Parameter(ParameterSetName = 'ByPersonalAccessToken')]
        [Parameter(ParameterSetName = 'ByCredential')]
        [string]
        $Proxy,

        [Parameter(ParameterSetName = 'ByPersonalAccessToken')]
        [Parameter(ParameterSetName = 'ByCredential')]
        [pscredential]
        $ProxyCredential,

        [Parameter(Mandatory,
            ParameterSetName = 'BySession')]
        [object]
        $Session,

        [Parameter()]
        [string]
        $Project,

        [Parameter()]
        [string]
        $RepositoryId, 

        [Parameter()]
        [string]
        $SearchCriteria_Author,

        [Parameter()]
        [string]
        $SearchCriteria_FromDate,

        [Parameter()]
        [string]
        $SearchCriteria_ToDate,

        [Parameter()]
        [int]
        $Skip,

        [Parameter()]
        [int]
        $Top
    )

    begin
    {
        If ($PSCmdlet.ParameterSetName -eq 'BySession')
        {
            $currentSession = $Session | Get-AzDevOpsSession
            If ($currentSession)
            {
                $Instance = $currentSession.Instance
                $Collection = $currentSession.Collection
                $PersonalAccessToken = $currentSession.PersonalAccessToken
                $Credential = $currentSession.Credential
                $Proxy = $currentSession.Proxy
                $ProxyCredential = $currentSession.ProxyCredential
                If ($currentSession.Version)
                {
                    $ApiVersion = (Get-AzDevOpsApiVersion -Version $currentSession.Version)
                }
                else
                {
                    $ApiVersion = $currentSession.ApiVersion
                }
            }
        }
    }
    
    process
    {
        $apiEndpoint = (Get-AzDevOpsApiEndpoint -ApiType 'git-commits') -f $RepositoryId
        $queryParameters = Set-AzDevOpsQueryParameters -InputObject $PSBoundParameters
        $setAzDevOpsUriSplat = @{
            Collection  = $Collection
            Instance    = $Instance
            Project     = $Project
            ApiVersion  = $ApiVersion
            ApiEndpoint = $apiEndpoint
            Query       = $queryParameters
        }
        [uri] $uri = Set-AzDevOpsUri @setAzDevOpsUriSplat
        $invokeAzDevOpsRestMethodSplat = @{
            Method              = 'GET'
            Uri                 = $uri
            Credential          = $Credential
            PersonalAccessToken = $PersonalAccessToken
            Proxy               = $Proxy
            ProxyCredential     = $ProxyCredential
        }
        $results = Invoke-AzDevOpsRestMethod @invokeAzDevOpsRestMethodSplat 
        If ($results.value)
        {
            return $results.value
        }
        else
        {
            return $results
        }
    }
    
    end
    {
    }
}