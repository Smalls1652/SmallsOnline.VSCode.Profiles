[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [string]$ProfilesListPath,
    [Parameter(Position = 1, Mandatory)]
    [string]$MarkdownTemplatePath,
    [Parameter(Position = 2, Mandatory)]
    [string]$ReadmePath
)

Write-Verbose "Getting profiles."
$profilesListJson = Get-Content -Path $ProfilesListPath -Raw

Write-Verbose "Getting template for README.md."
$markdownTemplateContent = Get-Content -Path $MarkdownTemplatePath -Raw

$scriptRoot = $PSScriptRoot
$importClassesScriptPath = Join-Path -Path $scriptRoot -ChildPath "Import-Classes.ps1"
$newProfileMdSectionScriptPath = Join-Path -Path $scriptRoot -ChildPath "New-ProfileMdSection.ps1"

Write-Verbose "Importing classes."
. $importClassesScriptPath

Write-Verbose "Deserializing profiles list from '$($ProfilesListPath)'."
$profilesList = [SmallsOnline.VSCode.Profiles.Models.CodeProfileJsonSerializer]::DeserializeProfileItemList($profilesListJson)

$profilesTocBuilder = [System.Text.StringBuilder]::new()
$profilesSectionBuilder = [System.Text.StringBuilder]::new()

foreach ($profileItem in $profilesList) {
    $profileSectionContent = . $newProfileMdSectionScriptPath -ProfileItem $profileItem
    
    $profileTocLink = $profileItem.DisplayName.ToLower().Replace(".", "")

    $null = $profilesTocBuilder.AppendLine("- [$($profileItem.DisplayName)](#$($profileTocLink))")
    $null = $profilesSectionBuilder.AppendLine($profileSectionContent)
}

$readmeContent = $markdownTemplateContent.Replace("{{ PROFILES_TOC }}", $profilesTocBuilder.ToString())
$readmeContent = $readmeContent.Replace("{{ PROFILES_SECTION }}", $profilesSectionBuilder.ToString())
$readmeContent = $readmeContent.TrimEnd([System.Environment]::NewLine)

Write-Verbose "Writing updated README.md content."
$readmeContent.Normalize() | Out-File -FilePath $ReadmePath -Encoding "UTF8"
