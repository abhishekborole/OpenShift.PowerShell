# Authentication and session guide

Supply tokens as SecureString using Read-Host or a trusted vault. Do not paste real tokens into shell history or scripts. `Get-OpenShiftCredential` returns identity-method metadata, not a retrievable credential. Public connection objects never contain HTTP clients, tokens, passwords or certificate private keys.

`Connect-OpenShift -Server ... -Token $token` validates HTTPS and `/version`, then registers the connection. `/version` can be anonymously accessible: successful connection means reachability and version retrieval, not proof of identity or resource permissions. Every resource request is still subject to API authentication and RBAC. A 401 requires reconnect with a new token; the module does not guess token lifetimes or assume OAuth refresh tokens exist. Kubernetes JWT expiry and OpenShift OAuth opaque-token expiry cannot be handled identically.

For X.509, pass an X509Certificate2 with its private key using `-Certificate`. Obtain it from the platform certificate store or load it using a secure password workflow. On Windows, use a provider-backed private key compatible with Schannel; a certificate constructed with an ephemeral PEM key may fail client authentication. No private keys are exported or persisted by the module.

For kubeconfig, `oc config view --raw -o json` reads the explicitly selected file into memory; no file is rewritten. Phase 1 accepts token entries only, rejects insecure TLS and exec plugins, resolves relative CA paths, and supports embedded CA certificates. Embedded CA certificates are public trust material written briefly to a temporary file; no credential file is created. Kubeconfig token files, legacy auth-provider blocks, embedded client key pairs and executable plugins need dedicated future adapters. Explicit `-Certificate` works independently of kubeconfig.

Existing kubeconfigs can themselves contain plaintext tokens. The module does not create them. Use your organization's secure kubeconfig handling policy. CLI operations use that file and could see external changes; the adapter rechecks server/TLS/plugin settings immediately before invocation, but cannot eliminate a concurrent file modification race. Use an access-controlled kubeconfig owned by the operator.

Username/password and OAuth browser flows vary by identity provider. They are not implemented by fabricating a universal Basic-auth flow or putting passwords on `oc` command lines. Use an established identity-provider login workflow and pass its resulting token. Implementing interactive secure login and refresh providers is an explicit later milestone.

## Multiple sessions

```powershell
Connect-OpenShift -Server https://api.lab.example:6443 -Token $labToken -Name lab
Connect-OpenShift -Server https://api.prod.example:6443 -Token $prodToken -Name prod
Set-OpenShiftConnection -Name lab
Set-OpenShiftContext -Connection lab -Namespace test
Get-OpenShiftResource pods -Group '' -Connection prod -Namespace production
```

`Set-OpenShiftContext` selects a connected session and local namespace. It does not call `oc config use-context`. To connect a different kubeconfig context, call Connect with that context and a new session name. Disconnect disposes local transport and token copies; it does not revoke an OAuth token at the server.

## TLS, proxy and persistence

Use `-CAFile` for a PEM CA bundle, or the OS trust store by default. There is no skip-validation switch. `-Proxy` accepts an HTTP(S) proxy URL without embedded credentials; explicit proxy credentials are not supported. Platform HttpClient proxy defaults apply when no override is supplied.

Windows optional persistence:

```powershell
Save-OpenShiftSession -Connection lab -Path ./lab.session.json -WhatIf
Save-OpenShiftSession -Connection lab -Path ./lab.session.json
Disconnect-OpenShift lab
Import-OpenShiftSession -Path ./lab.session.json -CAFile ./cluster-ca.pem
```

Save refuses overwrite and uses Windows DPAPI via ConvertFrom-SecureString without a portable key. Only the same user/machine can normally decrypt it. The file includes endpoint and namespace metadata. Import reconnects read-only, revalidates the endpoint and requires explicit custom CA/proxy settings again. Non-Windows persistence deliberately fails: use a trusted SecretManagement vault to retrieve a SecureString token there. No cross-platform plaintext fallback exists.
