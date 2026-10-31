Import-Module "$PSScriptRoot/../../OpenShift.PowerShell.psd1"
Describe 'Real HTTPS transport with a temporary private CA' {
    BeforeAll {
        $rsa = [Security.Cryptography.RSA]::Create(2048)
        $req = [Security.Cryptography.X509Certificates.CertificateRequest]::new('CN=OpenShift Test Root', $rsa, [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $req.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($true,$false,0,$true))
        $root = $req.CreateSelfSigned([DateTimeOffset]::UtcNow.AddMinutes(-5),[DateTimeOffset]::UtcNow.AddDays(1))
        $leafKey = [Security.Cryptography.RSA]::Create(2048)
        $leafReq = [Security.Cryptography.X509Certificates.CertificateRequest]::new('CN=localhost', $leafKey, [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $san = [Security.Cryptography.X509Certificates.SubjectAlternativeNameBuilder]::new(); $san.AddDnsName('localhost')
        $leafReq.CertificateExtensions.Add($san.Build())
        $leafReq.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($false,$false,0,$true))
        $eku = [Security.Cryptography.OidCollection]::new(); [void]$eku.Add([Security.Cryptography.Oid]::new('1.3.6.1.5.5.7.3.1'))
        $leafReq.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::new($eku,$true))
        $leaf = $leafReq.Create($root,[DateTimeOffset]::UtcNow.AddMinutes(-2),[DateTimeOffset]::UtcNow.AddHours(1),[byte[]](1,2,3,4))
        $clientKey = [Security.Cryptography.RSA]::Create(2048)
        $clientReq = [Security.Cryptography.X509Certificates.CertificateRequest]::new('CN=fixture-client', $clientKey, [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $clientEku = [Security.Cryptography.OidCollection]::new(); [void]$clientEku.Add([Security.Cryptography.Oid]::new('1.3.6.1.5.5.7.3.2'))
        $clientReq.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::new($clientEku,$true))
        $clientPublic = $clientReq.Create($root,[DateTimeOffset]::UtcNow.AddMinutes(-2),[DateTimeOffset]::UtcNow.AddHours(1),[byte[]](5,6,7,8))
        $script:clientCertificate = [Security.Cryptography.X509Certificates.RSACertificateExtensions]::CopyWithPrivateKey($clientPublic,$clientKey)
        if ($IsWindows) {
            # Schannel requires a provider-backed private key for client authentication.
            $portable = $script:clientCertificate.Export([Security.Cryptography.X509Certificates.X509ContentType]::Pfx)
            $script:clientCertificate.Dispose()
            $script:clientCertificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new($portable)
            [Array]::Clear($portable,0,$portable.Length)
        }
        $clientKey.Dispose(); $clientPublic.Dispose()
        $script:caFile = Join-Path $TestDrive ca.pem
        $certFile = Join-Path $TestDrive server.pem; $keyFile = Join-Path $TestDrive server.key; $portFile = Join-Path $TestDrive port.txt
        [IO.File]::WriteAllText($script:caFile,$root.ExportCertificatePem())
        [IO.File]::WriteAllText($certFile,$leaf.ExportCertificatePem())
        [IO.File]::WriteAllText($keyFile,$leafKey.ExportPkcs8PrivateKeyPem())
        $psi = [Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = (Get-Command python -CommandType Application | Select-Object -First 1).Source
        $psi.UseShellExecute=$false; $psi.CreateNoWindow=$true
        foreach ($arg in @("$PSScriptRoot/../Mock/https_api.py",$certFile,$keyFile,$portFile,$script:caFile)) { $psi.ArgumentList.Add($arg) }
        $script:server = [Diagnostics.Process]::Start($psi)
        for ($i=0; $i -lt 100 -and -not (Test-Path $portFile); $i++) { Start-Sleep -Milliseconds 100 }
        if (-not (Test-Path $portFile)) { throw 'Local HTTPS fixture did not start.' }
        $script:url = 'https://localhost:' + (Get-Content $portFile -Raw)
        $rsa.Dispose();$leafKey.Dispose();$root.Dispose();$leaf.Dispose()
    }
    AfterAll {
        try { Get-OpenShiftConnection | ForEach-Object { Disconnect-OpenShift -Connection $_.Name } }
        finally {
            if ($script:server) { if (-not $script:server.HasExited) { $script:server.Kill($true) }; $script:server.Dispose() }
            if ($script:clientCertificate) { $script:clientCertificate.Dispose() }
        }
    }
    It 'validates custom CA and sends a bearer token over HTTPS' {
        $token = ConvertTo-SecureString 'fixture-token' -AsPlainText -Force
        $null = Connect-OpenShift -Server $script:url -Token $token -CAFile $script:caFile -Name tls
        (Get-OpenShiftClusterInfo -Connection tls).Version.gitVersion | Should -Be v1.33.fixture
    }
    It 'rejects an untrusted certificate with the default trust store' {
        $token = ConvertTo-SecureString 'fixture-token' -AsPlainText -Force
        { Connect-OpenShift -Server $script:url -Token $token -Name untrusted } | Should -Throw '*transport failed*'
    }
    It 'authenticates using a real TLS client certificate without a bearer token' {
        $c = Connect-OpenShift -Server $script:url -Certificate $script:clientCertificate -CAFile $script:caFile -Name mtls
        $c.Authentication | Should -Be Certificate
        Test-OpenShiftConnection mtls | Should -BeTrue
    }
    It 'rejects hostname mismatch even with a trusted custom root' {
        $token = ConvertTo-SecureString 'fixture-token' -AsPlainText -Force
        { Connect-OpenShift -Server ($script:url.Replace('localhost','127.0.0.1')) -Token $token -CAFile $script:caFile -Name mismatch } | Should -Throw '*transport failed*'
    }
    It 'maps actual unauthorized responses without leaking body content' {
        $token = ConvertTo-SecureString 'wrong-fixture-token' -AsPlainText -Force
        { Connect-OpenShift -Server $script:url -Token $token -CAFile $script:caFile -Name wrong } | Should -Throw '*401*'
    }
    It 'blocks redirects and never follows the target host' {
        & (Get-Module OpenShift.PowerShell) {
            { Invoke-OSRequest -Session (Resolve-OSConnection tls) -Path '/version?redirect=1' } | Should -Throw '*302*'
        }
    }
    It 'serializes real write requests for all supported methods' {
        $token = ConvertTo-SecureString 'fixture-token' -AsPlainText -Force
        $null = Connect-OpenShift -Server $script:url -Token $token -CAFile $script:caFile -Name tls-write -Mode Administrative
        & (Get-Module OpenShift.PowerShell) {
            foreach ($method in @('POST','PUT','PATCH','DELETE')) {
                $r = Invoke-OSRequest -Session (Resolve-OSConnection tls-write) -Path /api/v1/namespaces -Method $method -Body @{metadata=@{name='fixture'}}
                $r.receivedName | Should -Be fixture
                $r.contentType | Should -Match application/json
            }
        }
    }
}
