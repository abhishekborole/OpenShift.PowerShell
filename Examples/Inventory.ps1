#requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][uri]$Server, [Parameter(Mandatory)][securestring]$Token, [string]$CAFile)
Import-Module "$PSScriptRoot/../OpenShift.PowerShell.psd1"
$null = Connect-OpenShift -Server $Server -Token $Token -CAFile $CAFile -Name inventory
try {
    Get-OpenShiftResource -Resource pods -Group '' -AllNamespaces -Connection inventory -ErrorAction Stop |
        Select-Object @{n='Namespace';e={$_.metadata.namespace}}, @{n='Name';e={$_.metadata.name}}, @{n='Phase';e={$_.status.phase}}
} finally { Disconnect-OpenShift inventory }
