# Cmdlet-to-API/CLI mapping

This matrix covers every command named in the product request. **Planned commands are not exported.** API versions are selected from live discovery; an absent operator/resource produces an explicit unsupported-capability error. Namespace segments are inserted only for namespaced resources. Discovery verbs describe server capabilities, not the caller's RBAC grants.

| Cmdlet | Engine | API/resource or mechanism | Status / constraints |
|---|---|---|---|
| `Connect-OpenShift` | REST + local/oc config | /version; secure token or X.509; oc config view only for kubeconfig | Implemented; interactive OAuth providers later |
| `Copy-OpenShiftPodFile` | CLI | oc cp with explicit container and file boundaries | Planned; tar and permissions preflight |
| `Disable-OpenShiftNodeScheduling` | REST | PATCH core / nodes; status.conditions, metadata.labels or spec.taints/unschedulable as applicable | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Disconnect-OpenShift` | Local | Dispose client and credential copy | Implemented; no server token revocation |
| `Enable-OpenShiftNodeScheduling` | REST | PATCH core / nodes; status.conditions, metadata.labels or spec.taints/unschedulable as applicable | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Enter-OpenShiftPod` | CLI interactive adapter | oc exec with explicit pod/container; remote command protocol | Planned; generic CLI currently rejects exec |
| `Expand-OpenShiftPersistentVolumeClaim` | REST | PATCH core PVC spec.resources.requests.storage | Planned; StorageClass allowVolumeExpansion and size validation |
| `Get-OpenShiftAPIResource` | REST | /api, /apis and served group/version discovery | Implemented |
| `Get-OpenShiftAPIServer` | REST | GET/list config.openshift.io / apiservers | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftAlert` | REST Prometheus | Trusted monitoring endpoint /api/v1/alerts | Planned |
| `Get-OpenShiftBuild` | REST | GET/list build.openshift.io / builds | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftBuildConfig` | REST | GET/list build.openshift.io / buildconfigs | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftCSIDriver` | REST | GET/list storage.k8s.io / csidrivers | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftCertificate` | REST projection | CertificateSigningRequests; selected TLS Secret certificate metadata | Planned; no private key output |
| `Get-OpenShiftCluster` | REST aggregate | /version; config.openshift.io clusterversions, infrastructures, clusteroperators | Planned |
| `Get-OpenShiftClusterCapacity` | REST aggregate | nodes allocatable/capacity; scheduled pod requests | Planned; reservations and units matter |
| `Get-OpenShiftClusterDiagnostic` | REST + CLI adapter | Resource evidence + explicit oc adm must-gather workflow | Planned; must-gather creates workloads and needs ShouldProcess |
| `Get-OpenShiftClusterHealth` | REST aggregate | clusteroperators conditions; nodes conditions | Planned |
| `Get-OpenShiftClusterInfo` | REST | GET /version | Implemented |
| `Get-OpenShiftClusterInventory` | REST aggregate | Selected discovered resources, stable typed CSV projection | Planned |
| `Get-OpenShiftClusterNetwork` | REST | GET/list config.openshift.io / networks | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftClusterOperator` | REST | GET/list config.openshift.io / clusteroperators | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftClusterOperatorStatus` | REST projection | config.openshift.io clusteroperators conditions | Planned |
| `Get-OpenShiftClusterRole` | REST | GET/list rbac.authorization.k8s.io / clusterroles | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftClusterRoleBinding` | REST | GET/list rbac.authorization.k8s.io / clusterrolebindings | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftClusterVersion` | REST | GET/list config.openshift.io / clusterversions | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftConfig` | REST discovery | config.openshift.io; explicit resource required | Planned; no invented generic config endpoint |
| `Get-OpenShiftConfigMap` | REST | GET/list core / configmaps | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftConnection` | Local | Session metadata | Implemented |
| `Get-OpenShiftContext` | Local/oc config | Session contexts or explicit kubeconfig | Implemented |
| `Get-OpenShiftCredential` | Local | Authentication metadata only | Implemented; never returns a token |
| `Get-OpenShiftCronJob` | REST | GET/list batch / cronjobs | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftDNS` | REST | GET/list config.openshift.io / dnses | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftDaemonSet` | REST | GET/list apps / daemonsets | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftDeployment` | REST | GET/list apps / deployments | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftDeploymentConfig` | REST | GET/list apps.openshift.io / deploymentconfigs | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftEgressIP` | REST | GET/list k8s.ovn.org / egressips | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftEvent` | REST | GET/list core / events | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftFeatureGate` | REST | GET/list config.openshift.io / featuregates | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftGroup` | REST | GET/list user.openshift.io / groups | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftImage` | REST | GET/list image.openshift.io / images | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftImageRegistry` | REST | GET/list imageregistry.operator.openshift.io / configs | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftImageStream` | REST | GET/list image.openshift.io / imagestreams | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftImageTag` | REST | GET/list image.openshift.io / imagestreamtags | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftInfrastructure` | REST | GET/list config.openshift.io / infrastructures | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftIngress` | REST | GET/list networking.k8s.io / ingresses | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftJob` | REST | GET/list batch / jobs | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftLimitRange` | REST | GET/list core / limitranges | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftLog` | REST / CLI explicit | Pod log API; optional oc adm node-logs adapter | Planned; permission and evidence scope required |
| `Get-OpenShiftMetrics` | REST Prometheus | Configured/discovered trusted monitoring endpoint /api/v1/query | Planned; independent endpoint trust/auth validation |
| `Get-OpenShiftMonitoringTarget` | REST Prometheus | Trusted monitoring endpoint /api/v1/targets | Planned |
| `Get-OpenShiftNamespace` | REST | GET/list core / namespaces | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftNetworkAttachmentDefinition` | REST | GET/list k8s.cni.cncf.io / network-attachment-definitions | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftNetworkPolicy` | REST | GET/list networking.k8s.io / networkpolicies | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftNode` | REST | GET/list core / nodes | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftNodeCondition` | REST | GET/list core / nodes; status.conditions, metadata.labels or spec.taints/unschedulable as applicable | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftNodeLabel` | REST | GET/list core / nodes; status.conditions, metadata.labels or spec.taints/unschedulable as applicable | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftNodeMetrics` | REST | metrics.k8s.io nodes if installed | Planned |
| `Get-OpenShiftNodeTaint` | REST | GET/list core / nodes; status.conditions, metadata.labels or spec.taints/unschedulable as applicable | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftOAuthClient` | REST | GET/list oauth.openshift.io / oauthclients | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftPersistentVolume` | REST | GET/list core / persistentvolumes | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftPersistentVolumeClaim` | REST | GET/list core / persistentvolumeclaims | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftPod` | REST | GET/list core / pods | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftPodContainer` | REST | GET/list core / pods; spec.containers and status.containerStatuses/phase | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftPodEvent` | REST | core events filtered by involvedObject UID | Planned |
| `Get-OpenShiftPodLog` | REST | core pods/{name}/log; container/previous/since options | Planned; follow needs streaming adapter |
| `Get-OpenShiftPodMetrics` | REST | metrics.k8s.io pods if installed | Planned |
| `Get-OpenShiftPodStatus` | REST | GET/list core / pods; spec.containers and status.containerStatuses/phase | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftProject` | REST | GET/list project.openshift.io / projects | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftReplicaSet` | REST | GET/list apps / replicasets | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftReplicationController` | REST | GET/list core / replicationcontrollers | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftResource` | REST | Discovered plural, scope, version and get/list verbs | Implemented |
| `Get-OpenShiftResourceQuota` | REST | GET/list core / resourcequotas | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftResourceUsage` | REST aggregate | metrics.k8s.io pods/nodes and resource requests | Planned |
| `Get-OpenShiftRole` | REST | GET/list rbac.authorization.k8s.io / roles | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftRoleBinding` | REST | GET/list rbac.authorization.k8s.io / rolebindings | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftRollout` | REST | workload generation/observedGeneration, conditions and revisions | Planned |
| `Get-OpenShiftRoute` | REST | GET/list route.openshift.io / routes | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftSecret` | REST | GET/list core / secrets | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftSecurityContextConstraint` | REST | GET/list security.openshift.io / securitycontextconstraints | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftService` | REST | GET/list core / services | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftServiceAccount` | REST | GET/list core / serviceaccounts | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftStatefulSet` | REST | GET/list apps / statefulsets | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftStorageCapacity` | REST | GET/list storage.k8s.io / csistoragecapacities | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftStorageClass` | REST | GET/list storage.k8s.io / storageclasses | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftUser` | REST | GET/list user.openshift.io / users | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftVM` | REST | GET/list kubevirt.io / virtualmachines | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftVirtualMachine` | REST | GET/list kubevirt.io / virtualmachines | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftVirtualMachineClone` | REST | GET/list clone.kubevirt.io / virtualmachineclones | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftVirtualMachineConsole` | WebSocket / virtctl adapter | KubeVirt VMI console or VNC subresource | Planned; not an oc console command |
| `Get-OpenShiftVirtualMachineDisk` | REST | GET/list kubevirt.io / virtualmachines and virtualmachineinstances; template volumes/devices/networks | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftVirtualMachineInstance` | REST | GET/list kubevirt.io / virtualmachineinstances | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftVirtualMachineMetrics` | REST Prometheus | Trusted endpoint; KubeVirt VM/VMI metric label selection | Planned |
| `Get-OpenShiftVirtualMachineMigration` | REST | GET/list kubevirt.io / virtualmachineinstancemigrations | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftVirtualMachineNetwork` | REST | GET/list kubevirt.io / virtualmachines and virtualmachineinstances; template volumes/devices/networks | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftVirtualMachineSnapshot` | REST | GET/list snapshot.kubevirt.io / virtualmachinesnapshots | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftVolumeSnapshot` | REST | GET/list snapshot.storage.k8s.io / volumesnapshots | Planned; validate discovery, scope and RBAC |
| `Get-OpenShiftVolumeSnapshotClass` | REST | GET/list snapshot.storage.k8s.io / volumesnapshotclasses | Planned; validate discovery, scope and RBAC |
| `Invoke-OpenShiftCLI` | CLI internal | ProcessStartInfo.ArgumentList, bounded process lifetime | Implemented internal; not exported |
| `Invoke-OpenShiftCommand` | CLI explicit | Allowlisted command families with explicit kubeconfig/context | Implemented; Administrative mode and ShouldProcess |
| `New-OpenShiftConfigMap` | REST | POST core / configmaps | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftDeployment` | REST | POST apps / deployments | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftImageStream` | REST | POST image.openshift.io / imagestreams | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftNamespace` | REST | POST core / namespaces | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftNetworkPolicy` | REST | POST networking.k8s.io / networkpolicies | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftNode` | REST workflow | machine.openshift.io Machines/MachineSets where available | Planned; Node object creation is not host provisioning |
| `New-OpenShiftPersistentVolumeClaim` | REST | POST core / persistentvolumeclaims | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftPod` | REST | POST core / pods | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftProject` | REST | POST project.openshift.io projectrequests | Planned; project request admission workflow |
| `New-OpenShiftResource` | REST | POST discovered collection | Planned; schema/capabilities/ShouldProcess |
| `New-OpenShiftRoute` | REST | POST route.openshift.io / routes | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftSecret` | REST | POST core / secrets | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftService` | REST | POST core / services | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftServiceAccount` | REST | POST core / serviceaccounts | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftStorageClass` | REST | POST storage.k8s.io / storageclasses | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftVirtualMachine` | REST | POST kubevirt.io / virtualmachines | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftVirtualMachineClone` | REST | POST clone.kubevirt.io / virtualmachineclones | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftVirtualMachineMigration` | REST | POST kubevirt.io / virtualmachineinstancemigrations | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `New-OpenShiftVirtualMachineSnapshot` | REST | POST snapshot.kubevirt.io / virtualmachinesnapshots | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Remove-OpenShiftDeployment` | REST | DELETE apps / deployments | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Remove-OpenShiftNamespace` | REST | DELETE core / namespaces | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Remove-OpenShiftNode` | REST | DELETE core / nodes | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Remove-OpenShiftPersistentVolumeClaim` | REST | DELETE core / persistentvolumeclaims | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Remove-OpenShiftPod` | REST | DELETE core / pods | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Remove-OpenShiftProject` | REST | DELETE project.openshift.io / projects | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Remove-OpenShiftResource` | REST | DELETE discovered resource | Planned; UID precondition and ShouldProcess |
| `Remove-OpenShiftRoute` | REST | DELETE route.openshift.io / routes | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Remove-OpenShiftSecret` | REST | DELETE core / secrets | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Remove-OpenShiftService` | REST | DELETE core / services | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Remove-OpenShiftStorageClass` | REST | DELETE storage.k8s.io / storageclasses | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Remove-OpenShiftVirtualMachine` | REST | DELETE kubevirt.io / virtualmachines | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Restart-OpenShiftDeployment` | REST | PATCH deployments spec.template.metadata.annotations restart timestamp | Planned |
| `Restart-OpenShiftNode` | CLI controlled diagnostic/host workflow | Drain/maintenance + approved node reboot mechanism | Planned; cluster-specific disruption safeguards required |
| `Restart-OpenShiftPod` | REST workflow | policy/v1 eviction and owning controller recreation | Planned; standalone pods cannot simply be restarted |
| `Restart-OpenShiftVirtualMachine` | REST | PUT subresources.kubevirt.io virtualmachines/{name}/restart | Planned; discover served version; pause is not memory-to-disk suspend |
| `Restore-OpenShiftVirtualMachineSnapshot` | REST | POST snapshot.kubevirt.io virtualmachinerestores referencing snapshot/target | Planned; stopped-target and restore conditions |
| `Resume-OpenShiftVirtualMachine` | REST | PUT subresources.kubevirt.io virtualmachineinstances/{name}/unpause | Planned; discover served version; pause is not memory-to-disk suspend |
| `Scale-OpenShiftDeployment` | REST | apps deployments/{name}/scale | Planned; approved-verb alternative Set with Replicas |
| `Set-OpenShiftConnection` | Local | Select default session | Implemented |
| `Set-OpenShiftContext` | Local | Select connected session and namespace | Implemented |
| `Set-OpenShiftDeployment` | REST | PATCH apps / deployments | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Set-OpenShiftNode` | REST | PATCH core / nodes | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Set-OpenShiftNodeLabel` | REST | PATCH core / nodes; status.conditions, metadata.labels or spec.taints/unschedulable as applicable | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Set-OpenShiftNodeTaint` | REST | PATCH core / nodes; status.conditions, metadata.labels or spec.taints/unschedulable as applicable | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Set-OpenShiftProject` | REST | PATCH project.openshift.io / projects | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Set-OpenShiftResource` | REST | PATCH/PUT discovered resource | Planned; resourceVersion and ShouldProcess |
| `Set-OpenShiftVirtualMachine` | REST | PATCH kubevirt.io / virtualmachines | Planned; validate discovery, scope and RBAC; ShouldProcess |
| `Start-OpenShiftBuild` | REST | POST build.openshift.io buildconfigs/{name}/instantiate | Planned; binary build instantiatebinary is a separate stream |
| `Start-OpenShiftVirtualMachine` | REST | PUT subresources.kubevirt.io virtualmachines/{name}/start | Planned; discover served version; pause is not memory-to-disk suspend |
| `Stop-OpenShiftVirtualMachine` | REST | PUT subresources.kubevirt.io virtualmachines/{name}/stop | Planned; discover served version; pause is not memory-to-disk suspend |
| `Suspend-OpenShiftVirtualMachine` | REST | PUT subresources.kubevirt.io virtualmachineinstances/{name}/pause | Planned; discover served version; pause is not memory-to-disk suspend |
| `Test-OpenShiftAPI` | REST | /version and selected authorized resource probe | Planned |
| `Test-OpenShiftConnection` | REST | GET /version | Implemented; reachability is not RBAC verification |
| `Test-OpenShiftDNS` | CLI/REST diagnostic workload | Explicit workload DNS resolution probe | Planned |
| `Test-OpenShiftNetworkConnectivity` | CLI/REST diagnostic workload | Explicit source namespace/node and destination probes | Planned; cannot infer reachability from object existence |
| `Undo-OpenShiftRollout` | CLI or REST workflow | oc rollout undo; Deployment ReplicaSet revision reconstruction | Planned; guarded revision selection |

Additional foundation exports: `Get-OpenShiftCLIVersion` (local oc client version), `Save-OpenShiftSession` (Windows DPAPI), and `Import-OpenShiftSession` (DPAPI decrypt then REST validation).

Additional virtualization resources to cover incrementally: `template.openshift.io/templates`, `cdi.kubevirt.io/datavolumes`, `datasources`, `storageprofiles`, `instancetype.kubevirt.io/virtualmachineinstancetypes`, `virtualmachineclusterinstancetypes`, `virtualmachinepreferences`, `virtualmachineclusterpreferences`, and VMI guest-agent subresources. All are reachable by generic reads when discovered; dedicated management commands are future work.

API sources and architectural decisions are linked in [Architecture](Architecture.md).
