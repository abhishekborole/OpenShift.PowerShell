function Get-OSProperty {
    param($Object, [string]$Name, $Default = $null)
    if ($Object -is [System.Collections.IDictionary]) { if ($Object.Contains($Name)) { return $Object[$Name] }; return $Default }
    if ($null -ne $Object -and $Object.PSObject.Properties[$Name]) { return $Object.$Name }
    return $Default
}
function Protect-OSResource {
    param($Object)
    # Recursively remove credentials and inline initialization payloads before returning data.
    if ($null -eq $Object) { return $null }
    if ($Object -is [string] -or $Object.GetType().IsValueType) { return $Object }
    if ($Object -is [array]) { return ,@($Object | ForEach-Object { Protect-OSResource $_ }) }
    if ((Get-OSProperty $Object 'kind' '') -match '^(User)?OAuth(Access|Authorize)Token$') {
        return [pscustomobject]@{ kind=(Get-OSProperty $Object 'kind'); metadata='[REDACTED: token identifiers are credentials]'; details='[REDACTED]' }
    }
    $copy = [ordered]@{}
    $properties = if ($Object -is [System.Collections.IDictionary]) { foreach ($key in $Object.Keys) { [pscustomobject]@{Name=$key;Value=$Object[$key]} } } else { $Object.PSObject.Properties }
    foreach ($p in $properties) {
        if ($p.Name -match '(?i)^(data|stringData|token|access_?Token|refresh_?Token|password|client_?Secret|secret|key|privateKey|client-key-data|userData|userDataBase64|networkData|networkDataBase64)$' -or $p.Name -eq 'kubectl.kubernetes.io/last-applied-configuration') { $copy[$p.Name] = '[REDACTED]' }
        elseif ($p.Name -eq 'value' -and (Get-OSProperty $Object 'name')) { $copy[$p.Name] = '[REDACTED]' }
        else { $copy[$p.Name] = Protect-OSResource $p.Value }
    }
    [pscustomobject]$copy
}
