function New-OSHttpClient {
    param([string]$CAFile, [uri]$Proxy, [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate, [int]$TimeoutSeconds = 30)
    if (-not ('OpenShift.TransportFactory' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Net;
using System.Net.Http;
using System.Net.Security;
using System.Security.Authentication;
using System.Security.Cryptography.X509Certificates;
namespace OpenShift {
 public static class TransportFactory {
  public static HttpClient Create(string ca, Uri proxy, X509Certificate2 certificate, int timeout) {
   var h = new HttpClientHandler { AllowAutoRedirect = false, SslProtocols = SslProtocols.Tls12 | SslProtocols.Tls13 };
   if (proxy != null) { h.Proxy = new WebProxy(proxy); h.UseProxy = true; }
   if (certificate != null) h.ClientCertificates.Add(certificate);
   if (!String.IsNullOrEmpty(ca)) {
    var roots = new X509Certificate2Collection(); roots.ImportFromPemFile(ca);
    if (roots.Count == 0) throw new ArgumentException("CA file contains no PEM certificates.");
    h.ServerCertificateCustomValidationCallback = (request, cert, chain, errors) => {
     if (cert == null || (errors & (SslPolicyErrors.RemoteCertificateNameMismatch | SslPolicyErrors.RemoteCertificateNotAvailable)) != 0) return false;
     using (var custom = new X509Chain()) {
      custom.ChainPolicy.TrustMode = X509ChainTrustMode.CustomRootTrust;
      custom.ChainPolicy.CustomTrustStore.AddRange(roots);
      custom.ChainPolicy.RevocationMode = X509RevocationMode.NoCheck;
      custom.ChainPolicy.ApplicationPolicy.Add(new System.Security.Cryptography.Oid("1.3.6.1.5.5.7.3.1"));
      if (chain != null) foreach (var element in chain.ChainElements) custom.ChainPolicy.ExtraStore.Add(element.Certificate);
      return custom.Build(cert);
     }
    };
   }
   return new HttpClient(h) { Timeout = TimeSpan.FromSeconds(timeout) };
  }
 }
}
'@
    }
    [OpenShift.TransportFactory]::Create($CAFile, $Proxy, $Certificate, $TimeoutSeconds)
}
function Send-OSHttp {
    param($Session, [string]$Method, [string]$Path, $Body, [string]$ContentType)
    $request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::new($Method), ($Session.Server + $Path))
    $response = $null
    try {
        $request.Headers.Accept.ParseAdd('application/json')
        if ($script:Secrets.ContainsKey($Session.Name)) {
            $plain = [System.Net.NetworkCredential]::new('', $script:Secrets[$Session.Name]).Password
            $request.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $plain)
            $plain = $null
        }
        if ($null -ne $Body) { $request.Content = [System.Net.Http.StringContent]::new(($Body | ConvertTo-Json -Depth 100 -Compress), [Text.Encoding]::UTF8, $ContentType) }
        $response = $Session.Client.SendAsync($request).GetAwaiter().GetResult()
        $content = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        $delay = 0
        if ($response.Headers.RetryAfter -and $response.Headers.RetryAfter.Delta) { $delay = [Math]::Ceiling($response.Headers.RetryAfter.Delta.TotalSeconds) }
        [pscustomobject]@{ StatusCode = [int]$response.StatusCode; Content = $content; RetryAfter = $delay }
    } catch { throw [System.InvalidOperationException]::new('OpenShift transport failed. Check server reachability, TLS trust, proxy and request timeout.') }
    finally { if ($response) { $response.Dispose() }; $request.Dispose() }
}
function Invoke-OSRequest {
    param($Session, [ValidateSet('GET','POST','PUT','PATCH','DELETE')][string]$Method = 'GET', [string]$Path, $Body = $null, [string]$ContentType = 'application/json')
    if ($Path -notmatch '^/(api(?:/|\?|$)|apis(?:/|\?|$)|version(?:\?|$)|openapi(?:/|\?|$))' -or $Path -match '(\\|\.\.|#|[\r\n])') { throw 'API path must be a local discovery or resource path.' }
    if ($Session.Mode -eq 'ReadOnly' -and $Method -ne 'GET') { throw 'Connection is read-only.' }
    for ($attempt = 0; $attempt -le 2; $attempt++) {
        $result = Send-OSHttp $Session $Method $Path $Body $ContentType
        Write-OSAudit $Session $Method $result.StatusCode
        if ($result.StatusCode -ge 200 -and $result.StatusCode -lt 300) {
            if ($result.Content) {
                try { return ($result.Content | ConvertFrom-Json -Depth 100 -ErrorAction Stop) }
                catch { throw 'API returned malformed or excessive-depth JSON. Response omitted to protect sensitive data.' }
            }; return
        }
        if ($Method -eq 'GET' -and $result.StatusCode -in @(429,502,503,504) -and $attempt -lt 2) {
            if ($result.RetryAfter -gt 60) { throw 'Server requested a retry delay over 60 seconds. Retry the operation later.' }
            Start-Sleep -Seconds ([Math]::Max($result.RetryAfter, [Math]::Pow(2,$attempt))); continue
        }
        $hint = switch ($result.StatusCode) { 401 {'Authentication expired or rejected; reconnect with a fresh credential.'} 403 {'RBAC denied this operation.'} 404 {'API or resource not available.'} 409 {'Conflict; read current resourceVersion before retrying.'} 410 {'Continuation/watch state expired; restart the read.'} 422 {'Resource validation failed.'} 429 {'Rate limited; retry later.'} default {'Request failed; inspect cluster diagnostics.'} }
        # Deliberately do not echo server bodies: admission errors can contain submitted secrets.
        throw [System.InvalidOperationException]::new("OpenShift HTTP $($result.StatusCode). $hint")
    }
}
