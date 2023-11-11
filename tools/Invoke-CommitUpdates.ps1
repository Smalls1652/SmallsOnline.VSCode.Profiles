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

$profilesPath = Join-Path -Path $RootPath -ChildPath "profiles"
$readmePath = Join-Path -Path $RootPath -ChildPath "README.md"

git add "$($profilesPath)/*"
git add "$($readmePath)"

$currentTimeStamp = [System.DateTimeOffset]::Now.UtcDateTime.ToString("yyyy-MM-dd HH:mm:ss zzz")

git commit --message "Update profiles [$($currentTimeStamp)]"
