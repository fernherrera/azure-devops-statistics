function Get-AzDevOpsGroupList
{
    <#
    .SYNOPSIS
    Returns a list of Azure Pipeline group accounts.

    .DESCRIPTION
    Returns a list of Azure Pipeline group accounts based on a filter query.

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

    .PARAMETER ScopeDescriptor
    Specify a non-default scope (collection, project) to search for groups.

    .PARAMETER SubjectTypes
    A comma separated list of user subject subtypes to reduce the retrieved results, e.g. Microsoft.IdentityModel.Claims.ClaimsIdentity

    .PARAMETER ContinuationToken
    An opaque data blob that allows the next page of data to resume immediately after where the previous page ended. The only reliable way to know if there is more data left is the presence of a continuation token.

    .INPUTS
    None, does not support the pipeline.

    .OUTPUTS
    PSObject, Azure Pipelines account(s)

    .EXAMPLE
    Returns group list for 'myCollection'.
    Get-AzDevOpsGroupList -Instance 'https://dev.azure.com' -Collection 'myCollection' -ApiVersion 5.0-preview

    .LINK
    https://docs.microsoft.com/en-us/rest/api/azure/devops/graph/groups/list?view=azure-devops-rest-5.0
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
        $ScopeDescriptor,

        [Parameter()]
        [string[]]
        $SubjectTypes,

        [Parameter()]
        [string]
        $ContinuationToken
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
        $apiEndpoint = Get-AzDevOpsApiEndpoint -ApiType 'graph-groups'
        $queryParameters = Set-AzDevOpsQueryParameters -InputObject $PSBoundParameters
        $setAzDevOpsUriSplat = @{
            Collection         = $Collection
            Instance           = $Instance
            ApiVersion         = $ApiVersion
            ApiEndpoint        = $apiEndpoint
            Query              = $queryParameters
            ApiSubDomainSwitch = 'vssps'
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
        If ($results.continuationToken)
        {
            $results.value
            $null = $PSBoundParameters.Remove('ContinuationToken')
            Get-AzDevOpsGroupList @PSBoundParameters -ContinuationToken $results.continuationToken
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