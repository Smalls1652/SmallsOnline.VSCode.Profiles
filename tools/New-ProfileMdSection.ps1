[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [SmallsOnline.VSCode.Profiles.Models.CodeProfileItem]$ProfileItem
)

$scriptRoot = $PSScriptRoot
$mdExtensionTableBuilderPath = Join-Path -Path $scriptRoot -ChildPath "New-ProfileExtensionsMdTable.ps1"

$profilePathResolved = (Resolve-Path -Path $ProfileItem.FilePath -ErrorAction "Stop").Path
$extensionsTable = . $mdExtensionTableBuilderPath -CodeProfilePath $profilePathResolved

$profileMdStringBuilder = [System.Text.StringBuilder]::new()

$null = $profileMdStringBuilder.AppendLine("### $($ProfileItem.DisplayName)")
$null = $profileMdStringBuilder.AppendLine()
$null = $profileMdStringBuilder.AppendLine("``./$($ProfileItem.FilePath)``")
$null = $profileMdStringBuilder.AppendLine()
$null = $profileMdStringBuilder.AppendLine($ProfileItem.Description)
$null = $profileMdStringBuilder.AppendLine()
$null = $profileMdStringBuilder.AppendLine("#### Extensions")
$null = $profileMdStringBuilder.AppendLine()
$null = $profileMdStringBuilder.Append($extensionsTable)

return $profileMdStringBuilder.ToString()
