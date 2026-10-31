#requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Connection, [Parameter(Mandatory)][string]$Namespace)
Import-Module "$PSScriptRoot/../OpenShift.PowerShell.psd1"
Get-OpenShiftAPIResource -Group kubevirt.io -Connection $Connection
Get-OpenShiftResource -Resource virtualmachines -Group kubevirt.io -Namespace $Namespace -Connection $Connection
Get-OpenShiftResource -Resource datavolumes -Group cdi.kubevirt.io -Namespace $Namespace -Connection $Connection
# Read-only migration inventory; execution is intentionally a later lifecycle adapter.
Get-OpenShiftResource -Resource virtualmachineinstancemigrations -Group kubevirt.io -Namespace $Namespace -Connection $Connection
