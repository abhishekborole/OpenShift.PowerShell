# Security and troubleshooting

Start with a least-privilege identity and the default ReadOnly mode. Administrative mode permits the advanced CLI adapter; confirmation and WhatIf still apply. ReadOnly is a module policy, not an RBAC boundary. Use Kubernetes authorization to enforce actual access restrictions.

The CLI adapter requires an explicit kubeconfig and context. It never builds a shell command or accepts token/password/server/identity overrides. Interactive login, exec and debug sessions require future dedicated adapters and are rejected by the generic command boundary. CLI output is raw and may contain secrets, especially get/describe/log operations. Do not save it to public artifacts. The public generic REST reader redacts known sensitive fields but cannot recognize arbitrary confidential application fields. Review exports before sharing them.

| Symptom | Action |
|---|---|
| HTTP 401 | Obtain fresh credentials and reconnect. No automatic replay with guessed refresh semantics. |
| HTTP 403 | Check get/list permissions for the requested resource and namespace. Narrow discovery Group if unrelated API groups are inaccessible. |
| HTTP 404 / absent resource | Refresh discovery and check installed CRDs/operators and served versions. |
| HTTP 409 | Re-read current resourceVersion before a future mutation retry. |
| HTTP 410 | Restart the paginated read; do not combine old and new snapshots. |
| Transport failed | Check HTTPS endpoint, DNS, routing, proxy, CA trust, certificate name/expiry and TimeoutSeconds. Server body and credentials are intentionally omitted. |
| Pagination cycle/budget | Treat prior emitted objects as partial. Increase MaxPages only for a legitimate large result. |
| CLI missing | Install a trusted OpenShift oc binary matching your cluster's supported version and put it on PATH. |
| CLI timed out | The child process tree is terminated. A server-side operation may already have succeeded; inspect state before retrying. |
| Existing connection name | Disconnect it explicitly or use a different Name. |
| DPAPI decrypt fails | Use the original Windows identity/machine, or obtain a new token. |

AuditPath records operation type, HTTP status, timestamp and connection name only. It does not capture manifests, tokens, resource URLs, query filters or CLI arguments. Protect audit files using OS permissions and rotate them externally. Default diagnostics are silent except through Verbose or errors.

SecureString narrows accidental exposure; it does not protect credentials from a compromised PowerShell process. HTTP headers necessarily contain the credential transiently in memory. Custom CA mode validates hostname and chain but does not perform revocation checking. Streaming cancellation, plugin allowlists, tamper-evident audit storage and broader proxy credential support belong to enterprise hardening.
