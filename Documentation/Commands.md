# Implemented command reference

Run `Get-Help <command> -Full` for binding and synopsis, and `Get-Command -Module OpenShift.PowerShell` for the actual exported surface.

| Command | Parameters and behavior |
|---|---|
| Connect-OpenShift | Server + SecureString Token, or Server + X509 Certificate, or KubeConfig + Context. Optional Name, Namespace, CAFile, Proxy, Mode, TimeoutSeconds, AuditPath. Returns safe connection metadata. |
| Disconnect-OpenShift | Connection (default active). Disposes transport and token copy; no remote revocation. |
| Get-OpenShiftConnection | Optional Name; lists safe sessions. |
| Set-OpenShiftConnection | Name; selects default. |
| Test-OpenShiftConnection | Connection; boolean `/version` reachability, not RBAC verification. |
| Get-OpenShiftContext | Optional KubeConfig; lists contexts from explicit file, otherwise connected session contexts. |
| Set-OpenShiftContext | Connection and optional Namespace; changes module state only. |
| Get-OpenShiftCredential | Connection; returns authentication metadata without secrets. |
| Get-OpenShiftClusterInfo | Connection; structured server `/version` and connection metadata. |
| Get-OpenShiftAPIResource | Connection, Group (default *), Name wildcard, AllVersions, Refresh. Includes discovered subresources. Core group is empty string. |
| Get-OpenShiftResource | Resource exact plural, Group, Name or wildcard, Namespace or AllNamespaces, LabelSelector, FieldSelector, PageSize, MaxPages, Connection. Returns sanitized native resource objects. |
| Get-OpenShiftCLIVersion | Runs `oc version --client -o json`, returns object. Does not assert cluster compatibility. |
| Invoke-OpenShiftCommand | Arguments string array, Connection, TimeoutSeconds; SupportsShouldProcess. Requires explicit Administrative kubeconfig session. Returns StdOut, StdErr and ExitCode. |
| Save-OpenShiftSession | Path, Connection; SupportsShouldProcess, Windows DPAPI only, refuses overwrite. |
| Import-OpenShiftSession | Path, optional CAFile and Proxy; reconnects read-only using DPAPI token. |

Supported common parameters include Verbose, Debug and ErrorAction through CmdletBinding. Resource objects retain metadata.name, metadata.namespace, spec and status. Typed Name/Status/Roles/CPU projections and mutation pipeline binding arrive with dedicated resource cmdlets in Phase 2. Do not assume the PowerCLI-like example commands from the roadmap are exported today.

Core resources often need `-Group ''` to avoid ambiguity with custom/operator resources. For all-namespace reads omit Name or use a wildcard; exact named reads require an explicit/default namespace. Kubernetes selectors are encoded and sent to the API, while wildcard name filtering is performed locally on paginated results. Known secret fields are always redacted in this release; there is no ShowSensitive switch.
