# Validation

Run `./Build/Test.ps1` with PowerShell 7.4+ and Pester 5.7.1. Unit tests cover exported connection/discovery/resource commands, credential privacy, error mapping, bounded retries, pagination, scope, redaction, read-only guards, CLI WhatIf, kubeconfig policy and Windows encrypted persistence. Separate local process tests launch the actual PowerShell executable and exercise literal argument transmission, stderr separation, timeout and failed exits. These are real local execution tests, not infrastructure certification.

The test suite also requires Python 3.10+ to host a temporary loopback HTTPS server. Temporary test CA and client certificates exercise real bearer and mutual-TLS authentication, untrusted/hostname-mismatched certificates, redirects and write serialization. These tests use no external service. The test suite uses Pester Mock against the internal request boundary for the remaining resource scenarios. It does not introduce a production `-Mock` connection mode or fake infrastructure results. Tests/Mock documents the mock seam; developers can supply response objects there or add fixtures with no production credentials. NUnit XML is written under ignored TestResults/; a failed BeforeAll/AfterAll fails the build as well as a failed assertion.

Opt-in lab tests:

```powershell
# Populate these environment variables through your approved secret injection process.
# OPENSHIFT_TEST_SERVER, OPENSHIFT_TEST_TOKEN, optional OPENSHIFT_TEST_CA
./Build/Test.ps1 -Integration
```

The integration suite reads server version, discovery and namespaces. It requires an explicitly authorized non-production cluster with appropriate RBAC. It does not mutate resources. Missing credentials fail explicitly rather than silently passing. The token environment variable is transient test plumbing; remove it from the session after the run. Do not commit a populated environment file.

CI runs on Ubuntu and Windows with the runner's installed PowerShell. Local baseline is PowerShell 7.4.13. CI alone does not establish all 7.4+ versions, Linux DPAPI behavior (unsupported), OpenShift 4.20+ compatibility or live KubeVirt compatibility. A future acceptance matrix must record those results individually.
