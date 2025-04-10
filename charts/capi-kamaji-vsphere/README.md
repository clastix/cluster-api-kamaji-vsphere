# capi-kamaji-vsphere

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.31.0](https://img.shields.io/badge/AppVersion-1.31.0-informational?style=flat-square)

A Helm chart for deploying a [Kamaji Tenant Cluster](https://github.com/clastix/kamaji) on vSphere using [Kamaji](https://github.com/clastix/cluster-api-control-plane-provider-kamaji) and [vSphere](https://github.com/kubernetes-sigs/cluster-api-provider-vsphere) providers.

**Homepage:** <https://kamaji.clastix.io>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Clastix Labs | <authors@clastix.labs> |  |

## Source Code

* <https://github.com/clastix/cluster-api-kamaji-vsphere>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cluster.controlPlane.addons.coreDNS | object | `{}` | KamajiControlPlane coreDNS configuration |
| cluster.controlPlane.addons.konnectivity | object | `{}` | KamajiControlPlane konnectivity configuration |
| cluster.controlPlane.addons.kubeProxy | object | `{}` | KamajiControlPlane kube-proxy configuration |
| cluster.controlPlane.apiServer | object | `{"extraArgs":["--cloud-provider=external"]}` | extraArgs for the control plane components |
| cluster.controlPlane.controllerManager.extraArgs[0] | string | `"--cloud-provider=external"` |  |
| cluster.controlPlane.dataStoreName | string | `"default"` | KamajiControlPlane dataStoreName |
| cluster.controlPlane.kubelet.cgroupfs | string | `"systemd"` | kubelet cgroupfs configuration |
| cluster.controlPlane.kubelet.preferredAddressTypes | list | `["InternalIP","ExternalIP","Hostname"]` | kubelet preferredAddressTypes order |
| cluster.controlPlane.labels | object | `{"cni":"calico"}` | Labels to add to the control plane |
| cluster.controlPlane.network.certSANs | list | `[]` | List of additional Subject Alternative Names to use for the API Server serving certificate |
| cluster.controlPlane.network.serviceAddress | string | `""` | Address used to expose the Kubernetes API server. If not set, the service will be exposed on the first available address. |
| cluster.controlPlane.network.serviceAnnotations | object | `{}` | Annotations to use for the control plane service |
| cluster.controlPlane.network.serviceLabels | object | `{}` | Labels to use for the control plane service |
| cluster.controlPlane.network.serviceType | string | `"LoadBalancer"` | Type of service used to expose the Kubernetes API server |
| cluster.controlPlane.replicas | int | `2` | Number of control plane replicas |
| cluster.controlPlane.version | string | `"v1.31.0"` | Kubernetes version |
| cluster.metrics.enabled | bool | `false` | Enable metrics collection. ServiceMonitor custom resource definition must be installed on the Management cluster. |
| cluster.metrics.serviceAccount | object | `{"name":"kube-prometheus-stack-prometheus","namespace":"monitoring-system"}` | ServiceAccount for scraping metrics |
| cluster.metrics.serviceAccount.name | string | `"kube-prometheus-stack-prometheus"` | ServiceAccount name used for scraping metrics |
| cluster.metrics.serviceAccount.namespace | string | `"monitoring-system"` | ServiceAccount namespace |
| cluster.name | string | `""` | Cluster name. If unset, the release name will be used |
| ipamProvider.enabled | bool | `true` | Enable the IPAMProvider usage |
| ipamProvider.gateway | string | `"192.168.0.1"` | IPAMProvider gateway |
| ipamProvider.prefix | string | `"24"` | IPAMProvider prefix |
| ipamProvider.ranges | list | `["192.168.0.0/24"]` | IPAMProvider ranges |
| nodePools[0].addressesFromPools | object | `{"enabled":true}` | Use an IPAMProvider pool to reserve IPs |
| nodePools[0].addressesFromPools.enabled | bool | `true` | Enable the IPAMProvider usage |
| nodePools[0].autoscaling.enabled | bool | `false` | Enable autoscaling |
| nodePools[0].autoscaling.labels.autoscaling | string | `"enabled"` | Labels to use for autoscaling: make sure to use the same labels on the autoscaler configuration |
| nodePools[0].autoscaling.maxSize | string | `"6"` | Maximum number of instances in the pool |
| nodePools[0].autoscaling.minSize | string | `"2"` | Minimum number of instances in the pool |
| nodePools[0].dataStore | string | `"datastore"` | VSphere datastore to use |
| nodePools[0].dhcp4 | bool | `false` | Use dhcp for ipv4 configuration |
| nodePools[0].diskGiB | int | `40` | Disk size of VM in GiB |
| nodePools[0].folder | string | `"default-pool"` | VSphere folder to store VMs |
| nodePools[0].memoryMiB | int | `4096` | Memory to allocate to worker VMs |
| nodePools[0].name | string | `"default"` |  |
| nodePools[0].nameServers | list | `["8.8.8.8"]` | Nameservers for VMs DNS resolution if required |
| nodePools[0].network | string | `"network"` | VSphere network for VMs and CSI |
| nodePools[0].numCPUs | int | `2` | Number of vCPUs to allocate to worker instances |
| nodePools[0].replicas | int | `3` | Number of worker VMs instances |
| nodePools[0].resourcePool | string | `"*/Resources"` | VSphere resource pool to use |
| nodePools[0].staticRoutes | list | `[]` | Static routes for VMs if required |
| nodePools[0].storagePolicyName | string | `""` | VSphere storage policy to use |
| nodePools[0].template | string | `"ubuntu-2204-kube-v1.31.0"` | VSphere template to clone |
| nodePools[0].users | list | `[{"name":"ubuntu","sshAuthorizedKeys":[],"sudo":"ALL=(ALL) NOPASSWD:ALL"}]` | Search domains suffixes if required searchDomains: [] # -- VM network domain if required domain: "" # -- IPv4 gateway if required gateway: "" # -- users to create on machines |
| vSphere.dataCenter | string | `"datacenter"` | Datacenter to use |
| vSphere.insecure | bool | `false` | If vCenter uses a self-signed cert |
| vSphere.password | string | `"changeme"` | vSphere password |
| vSphere.port | int | `443` | VSphere server port |
| vSphere.secret | object | `{"create":false,"name":"vsphere-secret"}` | Create a secret with the VSphere credentials |
| vSphere.secret.create | bool | `false` | Specifies whether Secret should be created from config values |
| vSphere.secret.name | string | `"vsphere-secret"` | The name of an existing Secret for vSphere.  |
| vSphere.server | string | `"server.sample.org"` | VSphere server dns name or address |
| vSphere.tlsThumbprint | string | `""` | VSphere https TLS thumbprint |
| vSphere.username | string | `"admin@vcenter"` | vSphere username |
| vSphereCloudControllerManager.enabled | bool | `true` | Installs vsphere-cloud-controller-manager on the management cluster |
| vSphereCloudControllerManager.password | string | `"changeme"` | vSphere password |
| vSphereCloudControllerManager.secret.create | bool | `false` | Specifies whether Secret should be created from config values |
| vSphereCloudControllerManager.secret.name | string | `"vsphere-config-secret"` | The name of an existing Secret for vSphere.  |
| vSphereCloudControllerManager.username | string | `"admin@vcenter"` | vSphere username |
| vSphereCloudControllerManager.version | string | `"v1.31.0"` | Version of the vsphere-cloud-controller-manager to install. The major and minor versions of releases should be equivalent to the compatible upstream Kubernetes release. |
| vSphereStorageControllerManager.enabled | bool | `false` | Installs vsphere-storage-controller-manager on the management cluster. NB: CSI node drivers are always installed on the workload cluster. |
| vSphereStorageControllerManager.logLevel | string | `"PRODUCTION"` | log level for the CSI components |
| vSphereStorageControllerManager.namespace | string | `"kube-system"` | Target namespace for the vSphere CSI node drivers on the workload cluster |
| vSphereStorageControllerManager.password | string | `"changeme"` | vSphere CSI password |
| vSphereStorageControllerManager.secret.create | bool | `false` | Specifies whether Secret should be created from config values |
| vSphereStorageControllerManager.secret.name | string | `"csi-config-secret"` | The name of an existing Secret for vSphere.  |
| vSphereStorageControllerManager.storageClass.allowVolumeExpansion | bool | `true` | Allow volume expansion |
| vSphereStorageControllerManager.storageClass.default | bool | `true` | Configure as the default storage class |
| vSphereStorageControllerManager.storageClass.enabled | bool | `false` | StorageClass enablement |
| vSphereStorageControllerManager.storageClass.name | string | `"vsphere-csi"` | Name of the storage class |
| vSphereStorageControllerManager.storageClass.parameters | object | `{}` | Optional storage class parameters |
| vSphereStorageControllerManager.storageClass.reclaimPolicy | string | `"Delete"` | Reclaim policy |
| vSphereStorageControllerManager.storageClass.volumeBindingMode | string | `"WaitForFirstConsumer"` | Volume binding mode |
| vSphereStorageControllerManager.username | string | `"admin@vcenter"` | vSphere CSI username |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
