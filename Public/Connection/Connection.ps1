function Connect-OpenShift {
    <# .SYNOPSIS
    Connects to an HTTPS Kubernetes/OpenShift API using a secure token, client certificate or token kubeconfig.
    .DESCRIPTION
    Validates /version before registering a session. Credentials remain private to the module.
    Kubeconfig is read through oc; executable credential plugins are not invoked.
    #>
    [CmdletBinding(DefaultParameterSetName='Token')]
    param(
        [Parameter(Mandatory,ParameterSetName='Token')][Parameter(Mandatory,ParameterSetName='Certificate')][uri]$Server,
        [Parameter(Mandatory,ParameterSetName='Token')][securestring]$Token,
        [Parameter(Mandatory,ParameterSetName='Certificate')][System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        [Parameter(Mandatory,ParameterSetName='KubeConfig')][string]$KubeConfig,
        [Parameter(ParameterSetName='KubeConfig')][string]$Context,
        [ValidatePattern('^[a-zA-Z0-9_.-]+$')][string]$Name = 'default',
        [string]$Namespace = 'default', [string]$CAFile, [uri]$Proxy,
        [ValidateSet('ReadOnly','Administrative')][string]$Mode = 'ReadOnly',
        [ValidateRange(1,300)][int]$TimeoutSeconds = 30, [string]$AuditPath
    )
    if ($script:Connections.ContainsKey($Name)) { throw "Connection '$Name' already exists. Disconnect it first or use another name." }
    $temporaryCA = $null
    try {
        if ($PSCmdlet.ParameterSetName -eq 'KubeConfig') {
            $KubeConfig = (Resolve-Path -LiteralPath $KubeConfig -ErrorAction Stop).Path
            $config = Read-OSKubeConfig $KubeConfig $Context
            if (Get-OSProperty $config.User 'exec') { throw 'Exec credential plugins are not enabled. Supply a SecureString token from your approved credential provider.' }
            if (Get-OSProperty $config.User 'auth-provider') { throw 'Legacy kubeconfig auth-provider credentials are not enabled.' }
            if ((Get-OSProperty $config.User 'client-key') -or (Get-OSProperty $config.User 'client-key-data')) { throw 'Kubeconfig client keys are not imported. Use the explicit -Certificate parameter.' }
            if (Get-OSProperty $config.Cluster 'insecure-skip-tls-verify' $false) { throw 'Insecure kubeconfig TLS settings are not permitted.' }
            $tokenValue = Get-OSProperty $config.User 'token'
            if (-not $tokenValue) { throw 'Phase 1 kubeconfig import requires a token. Use -Certificate for X.509 or obtain a fresh token using your identity provider.' }
            $Token = ConvertTo-SecureString $tokenValue -AsPlainText -Force; $tokenValue = $null
            $Server = [uri]$config.Cluster.server; $Context = $config.Context
            if (-not $PSBoundParameters.ContainsKey('Namespace')) { $Namespace = Get-OSProperty $config.ContextData 'namespace' 'default' }
            if (-not $Proxy -and (Get-OSProperty $config.Cluster 'proxy-url')) { $Proxy = [uri]$config.Cluster.'proxy-url' }
            if (-not $CAFile) {
                $caData = Get-OSProperty $config.Cluster 'certificate-authority-data'
                $caPath = Get-OSProperty $config.Cluster 'certificate-authority'
                if ($caData) {
                    $temporaryCA = [IO.Path]::GetTempFileName()
                    [IO.File]::WriteAllBytes($temporaryCA, [Convert]::FromBase64String($caData)); $CAFile = $temporaryCA
                } elseif ($caPath) {
                    $CAFile = if ([IO.Path]::IsPathRooted($caPath)) { $caPath } else { Join-Path (Split-Path $KubeConfig) $caPath }
                }
            }
            $config = $null
        }
        if ($Server.Scheme -ne 'https' -or $Server.UserInfo -or $Server.Query -or $Server.Fragment -or $Server.AbsolutePath -ne '/') { throw 'Server must be an HTTPS origin, without credentials, path, query or fragment.' }
        if ($Proxy -and ($Proxy.Scheme -notin @('http','https') -or $Proxy.UserInfo)) { throw 'Proxy must use HTTP(S) without embedded credentials.' }
        if ($Token -and $Token.Length -eq 0) { throw 'Token cannot be empty.' }
        if ($Certificate -and -not $Certificate.HasPrivateKey) { throw 'Client certificate requires its private key.' }
        if ($CAFile) { $CAFile = (Resolve-Path -LiteralPath $CAFile -ErrorAction Stop).Path }
        $session = [pscustomobject]@{
            Name=$Name; Server=$Server.AbsoluteUri.TrimEnd('/'); Namespace=$Namespace; Context=$Context
            KubeConfig=$KubeConfig; Mode=$Mode; Authentication=$(if ($Certificate) {'Certificate'} else {'Token'})
            ConnectedAt=[DateTime]::UtcNow; AuditPath=$AuditPath; Discovery=@{}; Proxy=$Proxy
            Client=(New-OSHttpClient -CAFile $CAFile -Proxy $Proxy -Certificate $Certificate -TimeoutSeconds $TimeoutSeconds)
        }
        if ($Token) { $script:Secrets[$Name] = $Token.Copy() }
        try { $null = Invoke-OSRequest -Session $session -Path '/version' }
        catch { $session.Client.Dispose(); $script:Secrets.Remove($Name); throw }
        $script:Connections[$Name] = $session; $script:DefaultConnection = $Name
        ConvertTo-OSConnectionInfo $session
    } finally { if ($temporaryCA) { Remove-Item -LiteralPath $temporaryCA -Force } }
}
function Get-OpenShiftConnection {
    <# .SYNOPSIS
    Lists connection metadata without credentials or HTTP clients.
    #>
    [CmdletBinding()] param([string]$Name)
    if ($Name) { ConvertTo-OSConnectionInfo (Resolve-OSConnection $Name) }
    else { foreach ($s in @($script:Connections.Values)) { ConvertTo-OSConnectionInfo $s } }
}
function Set-OpenShiftConnection {
    <# .SYNOPSIS
    Selects the default session. Does not alter kubeconfig.
    #>
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Name)
    $s = Resolve-OSConnection $Name; $script:DefaultConnection = $s.Name; ConvertTo-OSConnectionInfo $s
}
function Disconnect-OpenShift {
    <# .SYNOPSIS
    Disposes local sessions. Does not revoke server-side OAuth tokens.
    #>
    [CmdletBinding()] param([string]$Connection)
    $s = Resolve-OSConnection $Connection; $s.Client.Dispose()
    if ($script:Secrets.ContainsKey($s.Name)) { $script:Secrets[$s.Name].Dispose(); $script:Secrets.Remove($s.Name) }
    $script:Connections.Remove($s.Name)
    if ($script:DefaultConnection -eq $s.Name) { $script:DefaultConnection = $null }
}
function Test-OpenShiftConnection {
    <# .SYNOPSIS
    Checks API reachability with /version; this does not prove resource RBAC permissions.
    #>
    [CmdletBinding()] param([string]$Connection)
    $s = Resolve-OSConnection $Connection
    try { $null = Invoke-OSRequest -Session $s -Path '/version'; return $true } catch { Write-Verbose 'Connection test failed.'; return $false }
}
function Get-OpenShiftClusterInfo {
    <# .SYNOPSIS
    Reads the API server version and connection metadata.
    #>
    [CmdletBinding()] param([string]$Connection)
    $s = Resolve-OSConnection $Connection
    [pscustomobject]@{ Connection=$s.Name; Server=$s.Server; Version=(Invoke-OSRequest -Session $s -Path '/version') }
}
function Get-OpenShiftCredential {
    <# .SYNOPSIS
    Returns authentication metadata only; never returns the token.
    #>
    [CmdletBinding()] param([string]$Connection)
    $s = Resolve-OSConnection $Connection
    [pscustomobject]@{ Connection=$s.Name; Authentication=$s.Authentication; Refresh='Reconnect with a fresh credential after HTTP 401'; PersistedByDefault=$false }
}
function Get-OpenShiftContext {
    <# .SYNOPSIS
    Lists active session contexts or contexts from an explicitly supplied kubeconfig.
    #>
    [CmdletBinding()] param([string]$KubeConfig)
    if ($KubeConfig) {
        $path = (Resolve-Path -LiteralPath $KubeConfig).Path
        $data = (Invoke-OpenShiftCLI -Arguments @('--kubeconfig',$path,'config','view','-o','json')).StdOut | ConvertFrom-Json
        foreach ($ctx in $data.contexts) { [pscustomobject]@{ Name=$ctx.name; Cluster=$ctx.context.cluster; Namespace=(Get-OSProperty $ctx.context 'namespace' 'default'); Current=($ctx.name -ceq $data.'current-context') } }
    } else { Get-OpenShiftConnection | Select-Object Name,Context,Namespace,Server,IsDefault }
}
function Set-OpenShiftContext {
    <# .SYNOPSIS
    Selects an already connected session and optionally its default namespace.
    #>
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Connection, [ValidatePattern('^[a-z0-9]([-a-z0-9]*[a-z0-9])?$')][string]$Namespace)
    $s = Resolve-OSConnection $Connection
    if ($Namespace) { $s.Namespace = $Namespace }
    Set-OpenShiftConnection -Name $s.Name
}
