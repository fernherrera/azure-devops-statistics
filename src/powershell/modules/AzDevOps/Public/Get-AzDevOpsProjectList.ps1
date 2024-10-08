function Get-AzDevOpsProjectList
{
    <#
    .SYNOPSIS
    Returns a list of Azure Pipeline build projects.

    .DESCRIPTION
    Returns a list of Azure Pipeline build projects based on a filter query.

    .PARAMETER Instance
    The Team Services account or TFS server.

    .PARAMETER Collection
    For Azure DevOps the value for collection should be the name of your orginization. 
    For both Team Services and TFS The value should be DefaultCollection unless another collection has been created.

    .PARAMETER ApiVersion
    Version of the api to use.

    .PARAMETER PersonalAccessToken
    Personal access token used to authenticate that has been converted to a secure string. 
    It is recomended to uses an Azure Pipelines PS session to pass the personal access token parameter among funcitons, See New-AzDevOpsSession.
    https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=vsts

    .PARAMETER Credential
    Specifies a user account that has permission to send the request.

    .PARAMETER Proxy
    Use a proxy server for the request, rather than connecting directly to the Internet resource. Enter the URI of a network proxy server.

    .PARAMETER ProxyCredential
    Specifie a user account that has permission to use the proxy server that is specified by the -Proxy parameter. The default is the current user.

    .PARAMETER Session
    Azure DevOps PS session, created by New-AzDevOpsSession.

    .PARAMETER ContinuationToken
    A continuation token, returned by a previous call to this method, that can be used to return the next set of definitions.

    .PARAMETER Top
    The maximum number of definitions to return.

    .INPUTS
    None, does not support pipeline.

    .OUTPUTS
    PSObject, Azure Pipelines build(s)

    .EXAMPLE
    Returns project list for 'myFirstProject'.
    Get-AzDevOpsProjectList -Instance 'https://dev.azure.com' -Collection 'myCollection' -Project 'myFirstProject'

    .LINK
    https://docs.microsoft.com/en-us/rest/api/azure/devops/core/projects/list?view=azure-devops-rest-5.0
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
        $ContinuationToken,

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
        $apiEndpoint = Get-AzDevOpsApiEndpoint -ApiType 'project-projects'
        $queryParameters = Set-AzDevOpsQueryParameters -InputObject $PSBoundParameters
        $setAzDevOpsUriSplat = @{
            Collection  = $Collection
            Instance    = $Instance
            ApiVersion  = $ApiVersion
            ApiEndpoint = $apiEndpoint
            Query       = $queryParameters
        }
        [uri] $uri = Set-AzDevOpsUri @setAzDevOpsUriSplat
        $invokeAzDevOpsWebRequestSplat = @{
            Method              = 'GET'
            Uri                 = $uri
            Credential          = $Credential
            PersonalAccessToken = $PersonalAccessToken
            Proxy               = $Proxy
            ProxyCredential     = $ProxyCredential
        }
        $results = Invoke-AzDevOpsWebRequest @invokeAzDevOpsWebRequestSplat
        If ($results.continuationToken -and (-not($PSBoundParameters.ContainsKey('Top'))))
        {
            $results.value
            $null = $PSBoundParameters.Remove('ContinuationToken')
            Get-AzDevOpsProjectList @PSBoundParameters -ContinuationToken $results.continuationToken
        }
        elseIf ($results.value.count -eq 0)
        {
            return
        }
        elseIf ($results.value)
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