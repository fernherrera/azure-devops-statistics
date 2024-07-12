CREATE TABLE [dbo].[OrganizationStats]
(
    [OrganizationName] [varchar](100) NULL,
    [Timestamp] [datetime2] NULL,
    [Projects] [int] NULL,
    [BuildPipelines] [int] NULL,
    [Builds] [int] NULL,
    [BuildsCompleted] [int] NULL,
    [BuildCompletionPercentage] [varchar](10) NULL,
    [ReleasePipelines] [int] NULL,
    [Releases] [int] NULL,
    [ReleasesToProduction] [int] NULL,
    [ReleasesCompleted] [int] NULL,
    [ReleaseCompletionPercentage] [varchar](10) NULL
) ON [PRIMARY]
GO