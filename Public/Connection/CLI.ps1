function Get-OpenShiftCLIVersion {
    <# .SYNOPSIS
    Detects oc and returns client version information without connecting to a cluster.
    #>
    [CmdletBinding()] param()
    (Invoke-OpenShiftCLI -Arguments @('version','--client','-o','json')).StdOut | ConvertFrom-Json
}
function Invoke-OpenShiftCommand {
    <# .SYNOPSIS
    Runs an advanced oc command against the active session's explicit kubeconfig and context.
    .DESCRIPTION
    Requires Administrative mode because arbitrary CLI operations cannot be classified safely.
    Output is raw and can contain sensitive information. No tokens may be supplied in Arguments.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
    param([Parameter(Mandatory)][string[]]$Arguments, [string]$Connection, [ValidateRange(1,3600)][int]$TimeoutSeconds=60)
    $s = Resolve-OSConnection $Connection
    if ($s.Mode -ne 'Administrative') { throw 'Advanced CLI execution requires an Administrative connection.' }
    if (-not $s.KubeConfig -or -not $s.Context) { throw 'CLI execution requires an explicit kubeconfig-backed session.' }
    if (-not $Arguments.Count -or $Arguments[0] -notin @('get','describe','logs','api-resources','api-versions','version','explain','rollout','adm','apply','create','delete','patch','scale','set','label','annotate','wait','cp')) { throw 'Command is not permitted by the CLI boundary. Interactive/login/config/exec commands need a dedicated future adapter.' }
    foreach ($arg in $Arguments) {
        if ($arg -match '(?i)^--?(token|password|username|server|context|kubeconfig|cluster|user|certificate-authority|client-certificate|client-key|insecure-skip-tls-verify|as|as-group|as-uid|namespace|s|n)(=|$)' -or $arg -match '^-[sn].+' -or $arg -match '[\r\n]') { throw 'Authentication, endpoint, identity and namespace overrides are prohibited.' }
    }
    # Re-read to detect external kubeconfig edits before executing against the bound context.
    $config = Read-OSKubeConfig $s.KubeConfig $s.Context
    if ($config.Cluster.server.TrimEnd('/') -ne $s.Server -or (Get-OSProperty $config.User 'exec') -or (Get-OSProperty $config.User 'auth-provider') -or (Get-OSProperty $config.User 'client-key') -or (Get-OSProperty $config.User 'client-key-data') -or (Get-OSProperty $config.Cluster 'insecure-skip-tls-verify' $false)) { throw 'Kubeconfig changed or contains unsafe settings. Reconnect.' }
    if ($PSCmdlet.ShouldProcess($s.Name, 'Execute explicit oc operation')) {
        Write-OSAudit $s 'CLI'
        Invoke-OpenShiftCLI -Arguments (@('--kubeconfig',$s.KubeConfig,'--context',$s.Context,'--namespace',$s.Namespace) + $Arguments) -TimeoutSeconds $TimeoutSeconds
    }
}
