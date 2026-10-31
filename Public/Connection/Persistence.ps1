function Save-OpenShiftSession {
    <# .SYNOPSIS
    Saves an explicitly selected token with Windows DPAPI encryption for the current user and machine.
    .DESCRIPTION
    File contains only encrypted token and non-secret endpoint metadata. Import requires the same Windows identity.
    Custom CA, proxy, audit and CLI settings must be supplied again on import.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path, [string]$Connection)
    if (-not $IsWindows) { throw 'DPAPI persistence is available only on Windows. Use your approved secret vault on other platforms.' }
    $s = Resolve-OSConnection $Connection
    if (-not $script:Secrets.ContainsKey($s.Name)) { throw 'Only token sessions can be persisted.' }
    if (Test-Path -LiteralPath $Path) { throw 'Refusing to overwrite an existing session file.' }
    if ($PSCmdlet.ShouldProcess($Path, 'Save DPAPI encrypted session')) {
        $value = [ordered]@{ Schema=1; Name=$s.Name; Server=$s.Server; Namespace=$s.Namespace; Token=($script:Secrets[$s.Name] | ConvertFrom-SecureString) }
        # CreateNew closes the check/write overwrite race.
        $stream = [IO.File]::Open([IO.Path]::GetFullPath($Path),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try { $bytes = [Text.Encoding]::UTF8.GetBytes(($value | ConvertTo-Json)); $stream.Write($bytes) } finally { $stream.Dispose() }
    }
}
function Import-OpenShiftSession {
    <# .SYNOPSIS
    Decrypts a Windows DPAPI token and reconnects in read-only mode.
    #>
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Path, [string]$CAFile, [uri]$Proxy)
    if (-not $IsWindows) { throw 'DPAPI import requires Windows.' }
    $value = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($value.Schema -ne 1) { throw 'Unsupported session schema.' }
    Connect-OpenShift -Name $value.Name -Server $value.Server -Namespace $value.Namespace -Token ($value.Token | ConvertTo-SecureString -ErrorAction Stop) -CAFile $CAFile -Proxy $Proxy
}
