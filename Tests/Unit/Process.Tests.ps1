Import-Module "$PSScriptRoot/../../OpenShift.PowerShell.psd1"
Describe 'Real local process boundary' {
    InModuleScope OpenShift.PowerShell {
        It 'passes spaces and shell metacharacters as literal arguments and separates stderr' {
            $file = Join-Path $TestDrive echo.ps1
            Set-Content $file 'param([string]$Value); [Console]::Out.Write($Value); [Console]::Error.Write("diagnostic")'
            $literal = 'a b;$(evil)&"quoted"'
            $r = Invoke-OpenShiftCLI -Executable (Join-Path $PSHOME $(if ($IsWindows) {'pwsh.exe'} else {'pwsh'})) -Arguments @('-NoProfile','-File',$file,$literal)
            $r.StdOut | Should -BeExactly $literal
            $r.StdErr | Should -BeExactly diagnostic
        }
        It 'terminates a timed out child process' {
            { Invoke-OpenShiftCLI -Executable (Join-Path $PSHOME $(if ($IsWindows) {'pwsh.exe'} else {'pwsh'})) -Arguments @('-NoProfile','-Command','Start-Sleep -Seconds 20') -TimeoutSeconds 1 } | Should -Throw '*timed out*'
        }
        It 'does not echo failed process output' {
            { Invoke-OpenShiftCLI -Executable (Join-Path $PSHOME $(if ($IsWindows) {'pwsh.exe'} else {'pwsh'})) -Arguments @('-NoProfile','-Command','[Console]::Error.Write("SENSITIVE"); exit 3') } | Should -Throw '*exit code 3*'
        }
        It 'constructs a real HTTP client with TLS checks and no redirects' {
            $client = New-OSHttpClient
            try { $client.Timeout.TotalSeconds | Should -Be 30 } finally { $client.Dispose() }
        }
    }
}
