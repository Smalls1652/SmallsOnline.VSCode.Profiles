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
    $profileExtensionsContent = Get-Content -Path $profileExtensionsPath -Raw
    
    $profileObj = [pscustomobject]@{
        "name" = $profileItem.name;
        "icon" = $profileItem.icon;
        "extensions" = $profileExtensionsContent
    }

    $profileOutPath = Join-Path -Path $rootPathResolved -ChildPath ".resources/$($profileObj.name).code-profile"

    Write-Verbose "Writing profile to '$($profileOutPath)'."
    $profileObj | ConvertTo-Json -Compress | Out-File -FilePath $profileOutPath -Encoding "UTF8"
}
