function Invoke-OpenShiftCLI {
    param([string[]]$Arguments, [string]$Executable = 'oc', [ValidateRange(1,3600)][int]$TimeoutSeconds = 60)
    $command = Get-Command $Executable -CommandType Application -ErrorAction Stop | Select-Object -First 1
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $command.Source; $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true; $start.RedirectStandardInput = $true
    foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $start; $started = $false
    try {
        $started = $process.Start(); $process.StandardInput.Close()
        $out = $process.StandardOutput.ReadToEndAsync(); $err = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) { $process.Kill($true); throw 'CLI timed out; process tree terminated.' }
        $stdout = $out.GetAwaiter().GetResult(); $stderr = $err.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw "CLI failed with exit code $($process.ExitCode). Output suppressed to protect credentials." }
        [pscustomobject]@{ StdOut = $stdout; StdErr = $stderr; ExitCode = $process.ExitCode }
    } finally { if ($started -and -not $process.HasExited) { $process.Kill($true) }; $process.Dispose() }
}
function Read-OSKubeConfig {
    param([string]$KubeConfig, [string]$Context)
    $args = @('--kubeconfig', $KubeConfig, 'config','view','--raw','-o','json')
    # config view reads data only: no cluster calls and no exec credential plugins.
    $raw = (Invoke-OpenShiftCLI -Arguments $args).StdOut
    try { $data = $raw | ConvertFrom-Json -Depth 100 -ErrorAction Stop }
    catch { throw 'oc returned invalid kubeconfig JSON. Content omitted to protect credentials.' }
    finally { $raw = $null }
    if (-not $Context) { $Context = $data.'current-context' }
    $ctx = @($data.contexts | Where-Object name -CEQ $Context)
    if ($ctx.Count -ne 1) { throw 'Requested kubeconfig context not found or ambiguous.' }
    $cluster = @($data.clusters | Where-Object name -CEQ $ctx[0].context.cluster)
    $user = @($data.users | Where-Object name -CEQ $ctx[0].context.user)
    if ($cluster.Count -ne 1 -or $user.Count -ne 1) { throw 'Context must resolve to exactly one cluster and user.' }
    [pscustomobject]@{ Data = $data; Context = $Context; ContextData = $ctx[0].context; Cluster = $cluster[0].cluster; User = $user[0].user }
}
