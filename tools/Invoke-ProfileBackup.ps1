[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [string]$RootPath
)

$rootPathResolved = (Resolve-Path -Path $RootPath -ErrorAction "Stop").Path

if ([System.IO.FileAttributes]::Directory -notin (Get-Item -Path $rootPathResolved).Attributes) {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new("The path '$($rootPathResolved)' is not a directory."),
            "InvalidOperation",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $rootPathResolved
        )
    )
}

Write-Verbose "Getting all extensions applied to all profiles."
$vscodeUserExtensionsPath = Join-Path -Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)) -ChildPath ".vscode/extensions/extensions.json"
$vscodeUserExtensionsContent = Get-Content -Path $vscodeUserExtensionsPath -Raw | ConvertFrom-Json
$allProfilesExtensions = $vscodeUserExtensionsContent | Where-Object { $PSItem.metadata.isApplicationScoped -eq $true }

$vscodeUserPath = $null
if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
    $vscodeUserPath = Join-Path -Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)) -ChildPath "Library/Application Support/Code/User/"
}
elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)) {
    $vscodeUserPath = Join-Path -Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)) -ChildPath ".config/Code/User/"
}
else {
    $vscodeUserPath = Join-Path -Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)) -ChildPath "AppData/Roaming/Code/User/"
}

Write-Verbose "VSCode user path: '$($vscodeUserPath)'."

$settingsStoragePath = Join-Path -Path $vscodeUserPath -ChildPath "globalStorage/storage.json"
$profilesDirPath = Join-Path -Path $vscodeUserPath -ChildPath "profiles"

$settingsStorageJson = Get-Content -Path $settingsStoragePath -Raw | ConvertFrom-Json
$userDataProfiles = $settingsStorageJson.userDataProfiles

foreach ($profileItem in $userDataProfiles) {
    Write-Verbose "Processing profile '$($profileItem.name)'."
    $profileExtensionsPath = Join-Path -Path $profilesDirPath -ChildPath "$($profileItem.location)/extensions.json"
    $profileExtensionsContent = Get-Content -Path $profileExtensionsPath -Raw | ConvertFrom-Json

    $profileExtensions = [System.Collections.Generic.List[pscustomobject]]::new()
    foreach ($extensionItem in $allProfilesExtensions) {
        $extensionPackageJsonPath = Join-Path -Path $extensionItem.location.path -ChildPath "package.json"
        $extensionPackageJsonContent = Get-Content -Path $extensionPackageJsonPath -Raw | ConvertFrom-Json

        $profileExtensions.Add(
            [pscustomobject]@{
                "identifier"  = [pscustomobject]@{
                    "id"   = $extensionItem.identifier.id;
                    "uuid" = $extensionItem.identifier.uuid;
                };
                "displayName" = $extensionPackageJsonContent.displayName;
            }
        )
    }

    foreach ($extensionItem in $profileExtensionsContent) {
        $extensionPackageJsonPath = Join-Path -Path $extensionItem.location.path -ChildPath "package.json"
        $extensionPackageJsonContent = Get-Content -Path $extensionPackageJsonPath -Raw | ConvertFrom-Json

        $profileExtensions.Add(
            [pscustomobject]@{
                "identifier"  = [pscustomobject]@{
                    "id"   = $extensionItem.identifier.id;
                    "uuid" = $extensionItem.identifier.uuid;
                };
                "displayName" = $extensionPackageJsonContent.displayName;
            }
        )
    }
    
    $profileObj = [pscustomobject]@{
        "name"       = $profileItem.name;
        "icon"       = $profileItem.icon;
        "extensions" = ($profileExtensions | ConvertTo-Json -Compress);
    }

    $profileOutPath = Join-Path -Path $rootPathResolved -ChildPath "profiles/$($profileObj.name).code-profile"

    Write-Verbose "Writing profile to '$($profileOutPath)'."
    $profileObj | ConvertTo-Json -Compress | Out-File -FilePath $profileOutPath -Encoding "UTF8"
}
