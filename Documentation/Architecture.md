# Architecture and API analysis

## API families

Kubernetes core resources are under `/api/{version}`; named groups are under `/apis/{group}/{version}`. A namespaced resource normally uses `/namespaces/{namespace}/{plural}` beneath its version endpoint. Cluster-scoped resources omit that namespace segment. Discovery supplies plural names, kinds, supported verbs, scope and versions. The library caches discovery per connection, selects preferred served versions, and exposes `-AllVersions` and `-Refresh`. It does not assume an operator or CRD is installed.

Core resources include nodes, namespaces, pods, services, secrets, ConfigMaps, events, PVs and PVCs. Workloads use `apps`, `batch` and (where present) OpenShift `apps.openshift.io`. Networking uses `networking.k8s.io`, `k8s.cni.cncf.io`, and OpenShift network configuration groups. Storage resources span `storage.k8s.io`, `snapshot.storage.k8s.io`, the core API and operator-specific groups. RBAC uses `rbac.authorization.k8s.io`; SCCs use `security.openshift.io`.

OpenShift configuration objects use `config.openshift.io`. Other major groups include `project.openshift.io`, `route.openshift.io`, `image.openshift.io`, `build.openshift.io`, `user.openshift.io`, `oauth.openshift.io`, `operator.openshift.io`, `machine.openshift.io` and `machineconfiguration.openshift.io`. Operator installations introduce additional groups. The mapping is a design reference, while live discovery remains authoritative.

KubeVirt defines VM, VMI and migration resources in `kubevirt.io`; lifecycle actions such as start, stop and restart use discovered `subresources.kubevirt.io` endpoints. Pause/unpause target VMIs; a pause is not equivalent to saving VM memory to disk. Snapshots/restores use `snapshot.kubevirt.io`; clones use `clone.kubevirt.io`; instance types/preferences use `instancetype.kubevirt.io`. CDI import and clone orchestration uses `cdi.kubevirt.io`, including DataVolumes, DataSources and StorageProfiles. Network attachments use `k8s.cni.cncf.io`. Each adapter must validate served resources, versions, scope and verbs before use.

## Execution decisions

1. Resolve an explicit connection or the selected default; never borrow ambient `oc` cluster state.
2. Choose REST for discovery, CRUD, status, metrics APIs and non-streaming pod logs.
3. Use a named CLI adapter for CLI-specific diagnostics, packaging or interactive workflows. `oc` is complementary and not a general API fallback.
4. Verify read-only policy, operation capabilities and target identity. Public mutations must use `SupportsShouldProcess`.
5. Execute, audit metadata, map errors and return native objects. Preserve server `resourceVersion` and UIDs for future optimistic concurrency and delete preconditions.

The foundation implements steps needed by connection, discovery and resource reads, plus an explicit advanced CLI escape hatch. Later adapters will add generic mutations, streaming and typed projections without changing this foundation's API selection rule.

## Implementation boundaries

| Component | Location | Responsibility |
|---|---|---|
| Public functions | Public/ | Binding, help, policy, orchestration |
| Sessions | Private/Session | Named sessions, private credentials, safe metadata and audit records |
| HTTP | Private/API | HttpClient, TLS/CA/proxy, bounded GET retries, error mapping |
| CLI | Private/CLI | Executable lookup, ArgumentList, separate streams, timeout, process cleanup |
| Discovery | Private/Discovery | Group/version/resource discovery and per-session caches |
| Serialization | Private/Utilities | Native JSON objects, redacted known sensitive fields |
| Presentation | Formats/ | Explicit connection formatting |
| Tests | Tests/Unit, Tests/Integration | Isolated tests and opt-in lab acceptance |

Optional future Types and Classes directories are reserved for validated resource projections; they contain no dummy code. No dynamic functions are exported in this milestone. Generic resource discovery avoids command-name collisions and works with new CRDs without a release.

## Transport and reliability

Requests cannot change the connected origin. Redirects are disabled. The transport validates the server name even with a custom CA. Custom CA trust uses a separate chain rather than disabling validation globally. Custom-CA mode currently does not perform revocation checks; network-dependent CRL/OCSP policy remains an enterprise-readiness item.

Timeout defaults to 30 seconds per HTTP attempt. GET retries at most twice for 429/502/503/504, honoring delta Retry-After up to 60 seconds. Writes are not replayed. HTTP 401 asks for reconnect, 403 identifies RBAC denial, 404 identifies unavailable resources, 409 identifies a concurrency conflict and 410 requires restarting a continuation/watch. Response bodies are excluded from exceptions because they may echo submitted credentials. Audit failure stops the call rather than silently dropping the audit event. Audit logs contain connection name, timestamp, operation and status only.

Resource lists follow continuation tokens, detect cycles and enforce MaxPages. Any pagination error after emitted items explicitly leaves partial output: consumers must use `-ErrorAction Stop` before treating an export as complete. Discovery of a forbidden API group fails visibly; narrowing `-Group` can avoid unrelated inaccessible groups. OpenAPI schema and watch support are later additions; CRUD clients must not equate discovery with schema validation.

## Sources checked for this design

- [Kubernetes API architecture and discovery](https://kubernetes.io/docs/concepts/overview/kubernetes-api/)
- [Kubernetes API reference](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kubeconfig schema](https://kubernetes.io/docs/reference/config-api/kubeconfig.v1/)
- [Authentication and credential plugins](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)
- [OpenShift 4.20 authentication and authorization](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/authentication_and_authorization/index)
- [OpenShift 4.20 CLI tools](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/cli_tools/index)
- [KubeVirt operations](https://kubevirt.io/api-reference/master/operations.html)
- [CDI operations](https://kubevirt.io/cdi-api-reference/main/operations.html)
- [CDI DataVolume design](https://github.com/kubevirt/containerized-data-importer/blob/main/doc/datavolumes.md)

Target lab baseline: OpenShift 4.20 and newer with the installed operator versions discovered at runtime. Neither a version number nor API discovery alone proves functional compatibility; release acceptance requires lab tests.
