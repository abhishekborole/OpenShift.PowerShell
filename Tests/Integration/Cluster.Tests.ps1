BeforeAll {
    Import-Module "$PSScriptRoot/../../OpenShift.PowerShell.psd1" -Force
    if (-not $env:OPENSHIFT_TEST_SERVER -or -not $env:OPENSHIFT_TEST_TOKEN) { throw 'Set OPENSHIFT_TEST_SERVER and OPENSHIFT_TEST_TOKEN for an explicitly authorized test cluster.' }
    $token = ConvertTo-SecureString $env:OPENSHIFT_TEST_TOKEN -AsPlainText -Force
    $null = Connect-OpenShift -Server $env:OPENSHIFT_TEST_SERVER -Token $token -CAFile $env:OPENSHIFT_TEST_CA -Name integration
}
AfterAll { Disconnect-OpenShift -Connection integration }
Describe 'Read-only cluster acceptance' {
    It 'connects to a real API' { Test-OpenShiftConnection integration | Should -BeTrue }
    It 'discovers the core API' { @(Get-OpenShiftAPIResource -Group '' -Name pods).Count | Should -Be 1 }
    It 'reads namespaces under the supplied RBAC identity' { @(Get-OpenShiftResource namespaces -Group '').Count | Should -BeGreaterThan 0 }
}
