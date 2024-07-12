function New-AzDevOpsSession
{
    <#
    .SYNOPSIS
    Creates an Azure DevOps session.

    .DESCRIPTION
    Creates an Azure DevOps session.
    Use Save-AzDevOpsSession to persist the session data to disk.
    Save the session to a variable to pass the session to other functions.

    .PARAMETER SessionName
    The friendly name of the session.

    .PARAMETER Instance
    The Team Services account or TFS server.

    .PARAMETER Collection
    For Azure DevOps the value for collection should be the name of your orginization. 
    For both Team Services and TFS The value should be DefaultCollection unless another collection has been created.
    See example 1.

    .PARAMETER Project
    Project ID or project name.

    .PARAMETER PersonalAccessToken
    Personal access token used to authenticate that has been converted to a secure string. 
    It is recomended to uses an Azure DevOps session to pass the personal access token parameter among funcitons, See New-AzDevOpsSession.
    https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=vsts

    .PARAMETER Credential
    Specifies a user account that has permission to the project.

    .PARAMETER Version
    TFS version, this will provide the module with the api version mappings. 

    .PARAMETER ApiVersion
    Version of the api to use.

    .PARAMETER Proxy
    Use a proxy server for the request, rather than connecting directly to the Internet resource. Enter the URI of a network proxy server.

    .PARAMETER ProxyCredential
    Specifie a user account that has permission to use the proxy server that is specified by the -Proxy parameter. The default is the current user.

    .PARAMETER Path
    The path where module data will be stored, defaults to $Script:ModuleDataPath.

    .LINK
    Save-AzDevOpsSession
    Remove-AzDevOpsSession

    .INPUTS
    None, does not support pipeline.

    .OUTPUTS
    PSObject. New-AzDevOpsSession returns a PSObject that contains the following:
        Instance
        Collection
        PersonalAccessToken

    .EXAMPLE
    Creates a session with the name of 'AzurePipelinesPS' returning it to the $session variable.
    $newAzDevOpsSessionSplat = @{
        Collection = 'myCollection'
        Project = 'myFirstProject'
        Instance = 'https://dev.azure.com/'
        PersonalAccessToken = 'myToken'
        Version = 'vNext'
        SessionName = 'AzurePipelinesPS'
    }
    $session = New-AzDevOpsSession @newAzDevOpsSessionSplat 

    .EXAMPLE
    Creates a session with the name of 'myFirstSession' returning it to the $session variable. Then saves the session to disk for use after the session is closed.
    $newAzDevOpsSessionSplat = @{
        Collection = 'myCollection'
        Project = 'myFirstProject'
        Instance = 'https://dev.azure.com/'
        PersonalAccessToken = 'myToken'
        Version = 'vNext'
        SessionName = 'myFirstSession'
    }
    $session = New-AzDevOpsSession @newAzDevOpsSessionSplat
    $session | Save-AzDevOpsSession
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByPersonalAccessToken')]
    Param
    (
        [Parameter(Mandatory)]
        [string]
        $SessionName,

        [Parameter()]
        [uri]
        $Instance = 'https://dev.azure.com/',

        [Parameter(Mandatory)]
        [string]
        $Collection,

        [Parameter()]
        [string]
        $Project,

        [Parameter()]
        [ValidateSet('7.1','7.0','6.0','vNext', '2018 Update 2', '2018 RTW', '2017 Update 2', '2017 Update 1', '2017 RTW', '2015 Update 4', '2015 Update 3', '2015 Update 2', '2015 Update 1', '2015 RTW')]
        [Obsolete("[New-AzDevOpsSession]: Version has been deprecated and replaced with ApiVersion.")]
        [string]
        $Version,

        [Parameter(ParameterSetName = 'ByPersonalAccessToken')]
        [string]
        $PersonalAccessToken,

        [Parameter(ParameterSetName = 'ByCredential')]
        [pscredential]
        $Credential,

        [Parameter()]
        [string]
        $ApiVersion,

        [Parameter()]
        [string]
        $Proxy,

        [Parameter()]
        [pscredential]
        $ProxyCredential,
        
        [Parameter()]
        [string]
        $Path = $Script:ModuleDataPath
    )
    Process
    {
        If ($Version)
        {
            $ApiVersion = Get-AzDevOpsApiVersion -Version $Version
        }
        If (-not($ApiVersion))
        {
            Write-Error "[$($MyInvocation.MyCommand.Name)]: ApiVersion is required to create a session" -ErrorAction 'Stop'
        }
        [int] $_sessionIdcount = (Get-AzDevOpsSession | Sort-Object -Property 'Id' | Select-Object -Last 1 -ExpandProperty 'Id') + 1
        $_session = New-Object -TypeName PSCustomObject -Property @{
            Instance    = $Instance
            Collection  = $Collection
            Project     = $Project
            ApiVersion  = $ApiVersion
            SessionName = $SessionName
            Id          = $_sessionIdcount
        }
        If ($PersonalAccessToken)
        {
            $securedPat = (ConvertTo-SecureString -String $PersonalAccessToken -AsPlainText -Force)
            $_session | Add-Member -NotePropertyName 'PersonalAccessToken' -NotePropertyValue $securedPat
        }
        If ($Credential)
        {
            $_session | Add-Member -NotePropertyName 'Credential' -NotePropertyValue $Credential
        }
        If ($Proxy)
        {
            $_session | Add-Member -NotePropertyName 'Proxy' -NotePropertyValue $Proxy
        }
        If ($ProxyCredential)
        {
            $_session | Add-Member -NotePropertyName 'ProxyCredential' -NotePropertyValue $ProxyCredential
        }
        If ($null -eq $Global:_AzDevOpsSessions)
        {
            $Global:_AzDevOpsSessions = @()
        }
        $Global:_AzDevOpsSessions += $_session
        return $_session
    }
}