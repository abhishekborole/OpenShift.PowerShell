function Get-OSDiscovery {
    param($Session, [switch]$Refresh)
    if ($Refresh) { $Session.Discovery.Clear() }
    if (-not $Session.Discovery.ContainsKey('groups')) {
        $core = Invoke-OSRequest -Session $Session -Path '/api'
        $groups = Invoke-OSRequest -Session $Session -Path '/apis'
        $versions = @()
        foreach ($v in $core.versions) { $versions += [pscustomobject]@{ Group=''; Version=$v; Path="/api/$v"; Preferred=$true } }
        foreach ($g in $groups.groups) {
            foreach ($v in $g.versions) { $versions += [pscustomobject]@{ Group=$g.name; Version=$v.version; Path="/apis/$($v.groupVersion)"; Preferred=($g.preferredVersion.groupVersion -eq $v.groupVersion) } }
        }
        $Session.Discovery['groups'] = $versions
    }
    $Session.Discovery['groups']
}
function Get-OSResourceDiscovery {
    param($Session, [string]$Group, [switch]$AllVersions)
    foreach ($v in @(Get-OSDiscovery $Session)) {
        if ($null -ne $Group -and $Group -ne '*' -and $v.Group -ne $Group) { continue }
        if (-not $AllVersions -and -not $v.Preferred) { continue }
        if (-not $Session.Discovery.ContainsKey($v.Path)) {
            $Session.Discovery[$v.Path] = Invoke-OSRequest -Session $Session -Path $v.Path
        }
        foreach ($r in $Session.Discovery[$v.Path].resources) {
            [pscustomobject]@{ PSTypeName='OpenShift.APIResource'; Name=$r.name; Kind=$r.kind; Group=$v.Group; Version=$v.Version; Namespaced=$r.namespaced; Verbs=@($r.verbs); BasePath=$v.Path; Preferred=$v.Preferred }
        }
    }
}
