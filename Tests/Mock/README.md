# Mock seam

Use Pester `InModuleScope OpenShift.PowerShell` and mock `Send-OSHttp` to provide StatusCode, Content and RetryAfter. This retains retry/error behavior. Mock `Invoke-OSRequest` only for discovery/resource orchestration tests. Mock `Read-OSKubeConfig` for credential-policy unit tests; process tests exercise the actual process boundary independently. No mock mode is exposed to administrators.
