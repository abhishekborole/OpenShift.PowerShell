function Get-OpenShiftAPIResource {
    <# .SYNOPSIS
    Discovers resource names, scopes, API versions, verbs and subresources from the connected cluster.
    #>
    [CmdletBinding()] param([string]$Connection, [string]$Group = '*', [string]$Name = '*', [switch]$AllVersions, [switch]$Refresh)
    $s = Resolve-OSConnection $Connection
    if ($Refresh) { $null = Get-OSDiscovery $s -Refresh }
    Get-OSResourceDiscovery $s $Group -AllVersions:$AllVersions | Where-Object Name -Like $Name
}
function Get-OpenShiftResource {
    <# .SYNOPSIS
    Reads a discovered resource with pagination, selectors and optional wildcard name filtering.
    .DESCRIPTION
    Credentials and known inline sensitive fields are redacted. Arbitrary application fields can still contain confidential data.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Resource, [string]$Group = '*', [string]$Name,
        [string]$Namespace, [switch]$AllNamespaces, [string]$LabelSelector, [string]$FieldSelector,
        [ValidateRange(1,1000)][int]$PageSize=500, [ValidateRange(1,10000)][int]$MaxPages=1000, [string]$Connection)
    $s = Resolve-OSConnection $Connection
    $matches = @(Get-OpenShiftAPIResource -Connection $s.Name -Group $Group -Name $Resource | Where-Object { $_.Name -ceq $Resource -and $_.Name -notmatch '/' })
    if ($matches.Count -ne 1) { throw 'Resource is unavailable or ambiguous. Specify its exact plural name and -Group.' }
    $r = $matches[0]; $path = $r.BasePath
    if ($AllNamespaces -and $Namespace) { throw 'Use either -Namespace or -AllNamespaces.' }
    if ($r.Namespaced -and -not $AllNamespaces) {
        if (-not $Namespace) { $Namespace = $s.Namespace }
        if ($Namespace -notmatch '^[a-z0-9]([-a-z0-9]*[a-z0-9])?$') { throw 'Invalid namespace.' }
        $path += '/namespaces/' + [uri]::EscapeDataString($Namespace)
    } elseif (-not $r.Namespaced -and $Namespace) { throw 'Cluster-scoped resource does not accept -Namespace.' }
    $path += '/' + $r.Name
    $exact = $Name -and -not [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name)
    if ($exact -and $AllNamespaces) { throw 'An exact name requires a namespace. Omit -AllNamespaces.' }
    $verb = if ($exact) {'get'} else {'list'}
    if ($verb -notin $r.Verbs) { throw "Resource does not advertise '$verb'." }
    if ($exact) {
        if ($Name -match '[/\\?#]' -or $Name -in @('.','..')) { throw 'Invalid resource name.' }
        Protect-OSResource (Invoke-OSRequest -Session $s -Path ($path+'/'+[uri]::EscapeDataString($Name))); return
    }
    $next = ''; $seen = [Collections.Generic.HashSet[string]]::new()
    for ($page=0; $page -lt $MaxPages; $page++) {
        $query = @('limit='+$PageSize)
        if ($LabelSelector) { $query += 'labelSelector='+[uri]::EscapeDataString($LabelSelector) }
        if ($FieldSelector) { $query += 'fieldSelector='+[uri]::EscapeDataString($FieldSelector) }
        if ($next) { $query += 'continue='+[uri]::EscapeDataString($next) }
        $data = Invoke-OSRequest -Session $s -Path ($path+'?'+($query -join '&'))
        foreach ($item in $data.items) { if (-not $Name -or $item.metadata.name -like $Name) { Protect-OSResource $item } }
        $next = Get-OSProperty $data.metadata 'continue' ''
        if (-not $next) { return }
        if (-not $seen.Add($next)) { throw 'Server repeated a continuation token; partial results were returned.' }
    }
    throw 'Pagination limit reached; partial results were returned. Increase -MaxPages.'
}
