#requires -Version 7.4
[CmdletBinding()] param([switch]$Integration)
$ErrorActionPreference='Stop'
Import-Module Pester -RequiredVersion 5.7.1
$config = New-PesterConfiguration
$config.Run.Path = Join-Path $PSScriptRoot '../Tests/Unit'
if ($Integration) { $config.Run.Path = Join-Path $PSScriptRoot '../Tests/Integration' }
$config.Run.PassThru=$true
$config.Output.Verbosity='Detailed'
$resultDirectory = Join-Path $PSScriptRoot '../TestResults'
$null = New-Item -ItemType Directory -Path $resultDirectory -Force
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = Join-Path $resultDirectory $(if ($Integration) {'integration.xml'} else {'unit.xml'})
$result = Invoke-Pester -Configuration $config
if ($result.Result -ne 'Passed' -or $result.PassedCount -eq 0) { throw 'Tests failed or no tests ran.' }
