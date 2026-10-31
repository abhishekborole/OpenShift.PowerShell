# Incremental development and acceptance

## Phase 1 — this milestone

Repository, manifest/loader, connection/session state, token and client-certificate REST authentication, token kubeconfig import, safe metadata logging, HTTP engine, controlled CLI execution, resource discovery and generic read proof. Windows DPAPI persistence is optional. Unit/process tests and read-only integration harness accompany the implementation.

Phase 1 does not claim the entire authentication or CLI feature list from the product vision: identity-provider-specific username/password/OAuth login, automatic credential refresh, exec plugins, streaming/cancellation APIs and interactive sessions require further adapters. Version compatibility remains a lab gate. The module requires PowerShell 7.4+; 5.1 support must be evaluated separately, not simulated by weakening transport security.

## Phase 2 — core resource management

Implement typed cluster/node/project/pod/deployment/service/route/storage/RBAC adapters in small tested batches. Include Name/Namespace/Connection/UID identity on pipeline objects, wildcard filters and safe mutation binding. Generic New/Set/Remove must resolve discovery scope/verbs, use ShouldProcess, enforce read-only mode and resourceVersion/delete UID preconditions. Restart pod must use eviction for controller-owned workloads or explain the impact on standalone pods. Node provisioning must target Machines/MachineSets where supported; creating a Node API object does not provision a host.

## Phase 3 — advanced OpenShift

Monitoring adapters with explicit authenticated endpoints and independently validated trust, image/build APIs, operators, dynamic CRDs, OpenAPI schema discovery, watch streams with resourceVersion/410 recovery, throttling and cancellation. Prometheus metrics/alerts/targets are not Kubernetes CRUD resources; do not send tokens to arbitrary discovered URLs. Add approved identity-provider authentication and secure external vault providers.

## Phase 4 — virtualization

Implement VM/VMI lifecycle using discovered KubeVirt subresources; validate runStrategy, live state and capability availability. Snapshot/restore and clone flows must watch conditions and surface CSI capability failures. Migration checks need schedulability, storage accessibility, CPU compatibility and migration constraints. Add DataVolumes, VM templates, instance types/preferences, disk/network operations and guest-agent information. Console transport uses websocket/virtctl integration, not an invented oc console command. Migration examples must start with inventory and preflight, then require explicit target selection and confirmation.

## Phase 5 — enterprise readiness

Performance/load/RBAC tests, secure streaming, error taxonomy, packaging, PSScriptAnalyzer, coverage thresholds, supported OS/runtime matrix, operator/version matrix, signed release artifacts and documentation generated from tested public commands. Production-readiness claims require documented lab evidence.

## Acceptance gates for every increment

Every exported cmdlet performs real work and has tests. Unsupported features are documented, not placeholder functions. All mutations use ShouldProcess and read-only guards. Transport errors never trigger a fallback to another privilege/identity. Test real API fixtures and failure paths; separately run authorized lab integration tests. Record runtime, OpenShift, KubeVirt and CDI versions with results. Preserve backwards compatibility or document a versioned breaking change.
