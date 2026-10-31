# OpenShift.PowerShell

Native PowerShell administration for Red Hat OpenShift, inspired by the discoverability and object-oriented workflows of VMware PowerCLI. Independent community project; not a Red Hat or VMware product.

**0.1.0 is the Phase 1 foundation.** It connects to real HTTPS APIs, discovers installed resources, returns paginated resource objects and provides a controlled `oc` adapter. Dedicated node, workload, storage and virtualization management commands are planned, not exported placeholders. This release has not been validated against a live OpenShift cluster and is not a production certification.

## Install and connect

Use PowerShell **7.4 or newer**. Windows PowerShell 5.1 is not supported in this release: the transport and safe process runner depend on modern .NET. No administrator installation is required.

```powershell
Import-Module ./OpenShift.PowerShell.psd1
$token = Read-Host 'OpenShift token' -AsSecureString
Connect-OpenShift -Server https://api.cluster.example.com:6443 -Token $token -Name lab
Get-OpenShiftClusterInfo
Get-OpenShiftAPIResource -Group kubevirt.io
Get-OpenShiftResource -Resource pods -Group '' -Namespace production
Get-OpenShiftResource -Resource virtualmachines -Group kubevirt.io -Namespace production |
    Select-Object @{n='Name';e={$_.metadata.name}}, @{n='Status';e={$_.status.printableStatus}}
Disconnect-OpenShift -Connection lab
```

Install a custom cluster CA using `-CAFile ./cluster-ca.pem`. TLS verification is mandatory. A client certificate with its private key is supported through `-Certificate` instead of `-Token`.

For an existing token kubeconfig, install `oc` on PATH and connect explicitly:

```powershell
Connect-OpenShift -KubeConfig "$HOME/.kube/config" -Context my-lab -Name lab
Get-OpenShiftResource -Resource persistentvolumeclaims -Group '' -AllNamespaces
```

The module does not change your kubeconfig or its current context. It reads token kubeconfigs without running credential plugins. OAuth browser login, username/password challenges and exec-plugin authentication remain future adapters; obtain a token using your approved authentication workflow first. See [authentication](Documentation/Authentication.md).

## Architecture

Public commands call a common session resolver and one of two internal engines:

```text
Public commands -> session / read-only guard / ShouldProcess
                -> discovery -> REST transport -> native PowerShell objects
                -> explicit CLI adapter -> ProcessStartInfo.ArgumentList -> oc
```

REST handles discovery and structured resource reads without requiring `oc`. The REST engine also supports POST, PUT, PATCH and DELETE for future resource adapters, but no public resource mutation commands are exported yet. CLI execution requires an explicit kubeconfig connection in Administrative mode and confirmation. There is no automatic REST-to-CLI fallback after an API or RBAC failure.

Connections contain public metadata only. Tokens live separately as SecureString values and become plaintext transiently when constructing HTTP headers; SecureString is not an encrypted-memory guarantee on every platform. Optional Windows session persistence uses DPAPI encryption. HTTP redirects are blocked, TLS 1.2+ is required, and mutation requests are never automatically retried.

## Implemented commands

| Area | Commands |
|---|---|
| Connections | `Connect-OpenShift`, `Disconnect-OpenShift`, `Get-OpenShiftConnection`, `Set-OpenShiftConnection`, `Test-OpenShiftConnection` |
| Context and identity metadata | `Get-OpenShiftContext`, `Set-OpenShiftContext`, `Get-OpenShiftCredential` |
| Discovery and reads | `Get-OpenShiftClusterInfo`, `Get-OpenShiftAPIResource`, `Get-OpenShiftResource` |
| CLI | `Get-OpenShiftCLIVersion`, `Invoke-OpenShiftCommand` |
| Encrypted local persistence | `Save-OpenShiftSession`, `Import-OpenShiftSession` (Windows only) |

`Get-OpenShiftResource` supports exact or wildcard names, label and field selectors, explicit namespaces, all-namespace lists, pagination and a maximum page count. Resource fields retain their Kubernetes structure. Secrets, ConfigMap data, inline environment values and known initialization fields are redacted; arbitrary application fields can still contain confidential information. Raw CLI output is explicitly unredacted.

## Development and tests

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser
./Build/Test.ps1
```

Tests require Python 3.10+ for a loopback HTTPS fixture, in addition to PowerShell and Pester. Python is not a module runtime dependency. Unit tests use Pester mocks rather than a fake production connection mode. Local process tests check argument preservation, timeout and exit handling. Real HTTPS tests check bearer and client-certificate authentication, CA trust, hostname checks, redirects and request serialization. Opt-in integration tests make read-only requests to a real cluster; see [testing](Documentation/Testing.md). No production credentials are needed for unit tests.

## Project guides

- [Architecture, API research and decisions](Documentation/Architecture.md)
- [Complete requested cmdlet-to-API/CLI mapping](Documentation/Cmdlet-Mapping.md)
- [Authentication, TLS and persistence](Documentation/Authentication.md)
- [Implemented command reference](Documentation/Commands.md)
- [Security and troubleshooting](Documentation/Security-and-Troubleshooting.md)
- [Roadmap and acceptance gates](Documentation/Roadmap.md)
- [Executable inventory example](Examples/Inventory.ps1)
- [Virtualization discovery example](Examples/Virtualization.ps1)

The next milestone is typed core-resource commands with pipeline-safe identity and guarded mutations. Virtualization will follow capability discovery for KubeVirt, CDI, snapshots, clones, instance types and preferences. The mapping marks planned commands explicitly; their presence in documentation is not an implementation claim.
