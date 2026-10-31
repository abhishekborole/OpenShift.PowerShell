@{
    RootModule = 'OpenShift.PowerShell.psm1'
    ModuleVersion = '0.1.0'
    GUID = '44668c19-2ee2-4c93-94cf-1b771e4aa75a'
    Author = 'Abhishek Borole'
    Description = 'Discovery-driven OpenShift administration. Phase 1 foundation.'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    FunctionsToExport = @('Connect-OpenShift','Disconnect-OpenShift','Get-OpenShiftConnection','Set-OpenShiftConnection','Test-OpenShiftConnection','Get-OpenShiftContext','Set-OpenShiftContext','Get-OpenShiftCredential','Get-OpenShiftClusterInfo','Get-OpenShiftAPIResource','Get-OpenShiftResource','Invoke-OpenShiftCommand','Get-OpenShiftCLIVersion','Save-OpenShiftSession','Import-OpenShiftSession')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    FormatsToProcess = @('Formats/OpenShift.format.ps1xml')
    PrivateData = @{ PSData = @{ Tags = @('OpenShift','Kubernetes','KubeVirt'); LicenseUri = 'https://opensource.org/license/mit' } }
}
