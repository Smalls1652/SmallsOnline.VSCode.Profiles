[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [string]$CodeProfilePath,
    [Parameter(Position = 1)]
    [switch]$OutputToClipboard
)

class CodeProfileExtension {
    [string]$DisplayName
    [string]$ExtensionId

    CodeProfileExtension([string]$displayName, [string]$extensionId) {
        $this.DisplayName = $displayName
        $this.ExtensionId = $extensionId
    }
}

$codeProfilePathResolved = $null
try {
    $codeProfilePathResolved = (Resolve-Path -Path $CodeProfilePath -ErrorAction "Stop").Path
}
catch [System.Management.Automation.ItemNotFoundException] {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            $PSItem.Exception,
            "ResolvePathError",
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $CodeProfilePath
        )
    )
}
catch [System.Exception] {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            $PSItem.Exception,
            "UnknownResolvePathError",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $CodeProfilePath
        )
    )
}

$codeProfileItem = Get-Item -Path $codeProfilePathResolved -ErrorAction "Stop"
if ($codeProfileItem.Extension -ne ".code-profile") {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.IO.IOException]::new("The file extension must be '.code-profile'."),
            "InvalidCodeProfileExtension",
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $codeProfileItem
        )
    )
}

$codeProfileData = Get-Content -Path $codeProfileItem.FullName -Raw | ConvertFrom-Json
$codeProfileExtensions = foreach ($extensionItem in ($codeProfileData.extensions | ConvertFrom-Json | Sort-Object -Property "displayName")) {
    [CodeProfileExtension]::new($extensionItem.displayName, $extensionItem.identifier.id)
}

$mdTableStringBuilder = [System.Text.StringBuilder]::new()

$null = $mdTableStringBuilder.AppendLine("| Display Name | Extension ID |")
$null = $mdTableStringBuilder.AppendLine("| --- | --- |")

foreach ($extensionItem in $codeProfileExtensions) {
    $null = $mdTableStringBuilder.AppendLine("| $($extensionItem.DisplayName) | ``$($extensionItem.ExtensionId)`` |")
}

$mdTableString = $mdTableStringBuilder.ToString()

if ($OutputToClipboard) {
    Set-Clipboard -Value $mdTableString
}
else {
    return $mdTableString
}
