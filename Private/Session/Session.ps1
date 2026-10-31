function Resolve-OSConnection {
    param([string]$Connection)
    if (-not $Connection) { $Connection = $script:DefaultConnection }
    if (-not $Connection -or -not $script:Connections.ContainsKey($Connection)) { throw 'No active connection. Run Connect-OpenShift or specify -Connection.' }
    $script:Connections[$Connection]
}
function ConvertTo-OSConnectionInfo {
    param($Session)
    [pscustomobject]@{
        PSTypeName = 'OpenShift.Connection'; Name = $Session.Name; Server = $Session.Server
        Namespace = $Session.Namespace; Context = $Session.Context; Mode = $Session.Mode
        Authentication = $Session.Authentication; IsDefault = ($Session.Name -eq $script:DefaultConnection)
        ConnectedAt = $Session.ConnectedAt
    }
}
function Write-OSAudit {
    param($Session, [string]$Operation, [int]$StatusCode = 0)
    # No request/response bodies, query values, URLs, credentials or CLI arguments.
    Write-Verbose "OpenShift operation=$Operation status=$StatusCode"
    if ($Session.AuditPath) {
        [pscustomobject]@{ Time = [DateTime]::UtcNow.ToString('o'); Connection = $Session.Name; Operation = $Operation; StatusCode = $StatusCode } |
            ConvertTo-Json -Compress | Add-Content -LiteralPath $Session.AuditPath -Encoding utf8 -ErrorAction Stop
    }
}
