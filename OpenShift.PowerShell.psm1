#requires -Version 7.4
Set-StrictMode -Version Latest
$script:Connections = @{}
$script:DefaultConnection = $null
$script:Secrets = @{}
foreach ($folder in @('Private','Public')) {
    Get-ChildItem (Join-Path $PSScriptRoot $folder) -Filter *.ps1 -Recurse | Sort-Object FullName | ForEach-Object { . $_.FullName }
}
$ExecutionContext.SessionState.Module.OnRemove = {
    foreach ($session in $script:Connections.Values) { $session.Client.Dispose() }
    foreach ($credential in $script:Secrets.Values) { $credential.Dispose() }
    $script:Connections.Clear(); $script:Secrets.Clear()
}
Export-ModuleMember -Function @(
    'Connect-OpenShift','Disconnect-OpenShift','Get-OpenShiftConnection','Set-OpenShiftConnection',
    'Test-OpenShiftConnection','Get-OpenShiftContext','Set-OpenShiftContext','Get-OpenShiftCredential',
    'Get-OpenShiftClusterInfo','Get-OpenShiftAPIResource','Get-OpenShiftResource',
    'Invoke-OpenShiftCommand','Get-OpenShiftCLIVersion','Save-OpenShiftSession','Import-OpenShiftSession'
)
