# capi-kamaji-vsphere

![Version: 0.2.6](https://img.shields.io/badge/Version-0.2.6-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.32.0](https://img.shields.io/badge/AppVersion-1.32.0-informational?style=flat-square)

A Helm chart for deploying a Kamaji Tenant Cluster on vSphere using Cluster API and Kamaji.

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
| cluster.clusterNetwork.apiServerPort | int | `6443` | API Server port |
| cluster.clusterNetwork.pods.cidrBlocks | list | `["10.93.0.0/16"]` | CIDR range for pods |
| cluster.clusterNetwork.serviceDomain | string | `"cluster.local"` | Service Domain for cluster DNS |
| cluster.clusterNetwork.services.cidrBlocks | list | `["10.96.0.0/16"]` | CIDR range for services |
| cluster.controlPlane.addons.coreDNS | object | `{}` | KamajiControlPlane coreDNS configuration |
| cluster.controlPlane.addons.konnectivity | object | `{}` | KamajiControlPlane konnectivity configuration |
| cluster.controlPlane.addons.kubeProxy | object | `{}` | KamajiControlPlane kube-proxy configuration |
| cluster.controlPlane.apiServer | object | `{"extraArgs":[]}` | extraArgs for the control plane components |
| cluster.controlPlane.controllerManager.extraArgs[0] | string | `"--cloud-provider=external"` |  |
| cluster.controlPlane.dataStoreName | string | `"default"` | KamajiControlPlane dataStoreName |
| cluster.controlPlane.deployment | object | `{"additionalMetadata":{"annotations":{},"labels":{}},"affinity":{},"nodeSelector":{"kubernetes.io/os":"linux"},"podAdditionalMetadata":{"annotations":{},"labels":{}},"tolerations":[],"topologySpreadConstraints":[]}` | Configure how KamajiControlPlane deployment should be done |
| cluster.controlPlane.deployment.additionalMetadata | object | `{"annotations":{},"labels":{}}` | Additional metadata as labels and annotations |
| cluster.controlPlane.deployment.affinity | object | `{}` | Affinity scheduling rules |
| cluster.controlPlane.deployment.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | NodeSelector for scheduling |
| cluster.controlPlane.deployment.podAdditionalMetadata | object | `{"annotations":{},"labels":{}}` | Pods Additional metadata as labels and annotations |
| cluster.controlPlane.deployment.tolerations | list | `[]` | Tolerations for scheduling |
| cluster.controlPlane.deployment.topologySpreadConstraints | list | `[]` | TopologySpreadConstraints for scheduling |
| cluster.controlPlane.kubelet.cgroupfs | string | `"systemd"` | kubelet cgroupfs configuration |
| cluster.controlPlane.labels | object | `{"cni":"calico"}` | Labels to add to the control plane |
| cluster.controlPlane.network.certSANs | list | `[]` | List of additional Subject Alternative Names to use for the API Server serving certificate |
| cluster.controlPlane.network.serviceAddress | string | `""` | Address used to expose the Kubernetes API server. If not set, the service will be exposed on the first available address. |
| cluster.controlPlane.network.serviceAnnotations | object | `{}` | Annotations to use for the control plane service |
| cluster.controlPlane.network.serviceLabels | object | `{}` | Labels to use for the control plane service |
| cluster.controlPlane.network.serviceType | string | `"LoadBalancer"` | Type of service used to expose the Kubernetes API server |
| cluster.controlPlane.replicas | int | `2` | Number of control plane replicas |
| cluster.controlPlane.scheduler.extraArgs | list | `[]` |  |
| cluster.controlPlane.version | string | `"v1.32.0"` | Kubernetes version |
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
| nodePools[0].staticRoutes | list | `[]` | Static network routes if required |
| nodePools[0].storagePolicyName | string | `""` | VSphere storage policy to use |
| nodePools[0].template | string | `"ubuntu-2404-kube-v1.32.0"` | VSphere template to clone |
| nodePools[0].users | list | `[{"lockPassword":true,"name":"ubuntu","shell":"/bin/bash","sshAuthorizedKeys":[],"sudo":"ALL=(ALL) NOPASSWD:ALL"}]` | users to create on machines |
| nodePools[0].users[0] | object | `{"lockPassword":true,"name":"ubuntu","shell":"/bin/bash","sshAuthorizedKeys":[],"sudo":"ALL=(ALL) NOPASSWD:ALL"}` | username to create |
| nodePools[0].users[0].lockPassword | bool | `true` | Lock login password |
| nodePools[0].users[0].shell | string | `"/bin/bash"` | SSH shell to use |
| nodePools[0].users[0].sshAuthorizedKeys | list | `[]` | SSH public key to add |
| nodePools[0].users[0].sudo | string | `"ALL=(ALL) NOPASSWD:ALL"` | sudoers configuration |
| vSphere.caFile | string | `""` | Path to the CA file if it has been mounted into the pod. |
| vSphere.dataCenter | string | `"datacenter"` | Datacenter to use |
| vSphere.identityRef | object | `{"name":"vsphere-secret","type":"Secret"}` | VSphere Identity Management |
| vSphere.identityRef.name | string | `"vsphere-secret"` | Specifies the name of the VSphereClusterIdentity or Secret |
| vSphere.identityRef.type | string | `"Secret"` | Specifies whether use VSphereClusterIdentity or Secret |
| vSphere.insecure | bool | `false` | If vCenter uses a self-signed cert |
| vSphere.port | int | `443` | VSphere server port |
| vSphere.server | string | `"server.sample.org"` | VSphere server dns name or address |
| vSphere.tlsThumbprint | string | `""` | VSphere https TLS thumbprint |
| vSphereCloudControllerManager.additionalMetadata.annotations | object | `{}` |  |
| vSphereCloudControllerManager.additionalMetadata.labels | object | `{}` |  |
| vSphereCloudControllerManager.affinity | object | `{}` | Affinity scheduling rules |
| vSphereCloudControllerManager.image | object | `{"pullPolicy":"IfNotPresent","registry":"registry.k8s.io","repository":"cloud-pv-vsphere/cloud-provider-vsphere","tag":"v1.32.0"}` | Image of the vsphere-cloud-controller-manager to install.  |
| vSphereCloudControllerManager.image.pullPolicy | string | `"IfNotPresent"` | Set the image pull policy. |
| vSphereCloudControllerManager.image.registry | string | `"registry.k8s.io"` | Set the image registry |
| vSphereCloudControllerManager.image.repository | string | `"cloud-pv-vsphere/cloud-provider-vsphere"` | Set the image repository |
| vSphereCloudControllerManager.image.tag | string | `"v1.32.0"` | The tag should be equivalent to the upstream Kubernetes version. |
| vSphereCloudControllerManager.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | NodeSelector for scheduling |
| vSphereCloudControllerManager.podAdditionalMetadata | object | `{"annotations":{},"labels":{}}` | Pods Additional metadata as labels and annotations |
| vSphereCloudControllerManager.secret.name | string | `"vsphere-config-secret"` | The name of an existing Secret to access the vCenter API |
| vSphereCloudControllerManager.tolerations | list | `[]` | Tolerations for scheduling |
| vSphereCloudControllerManager.topology | object | `{"region":"k8s-region","zone":"k8s-zone"}` | Labels for toplogy regions and zones |
| vSphereCloudControllerManager.topologySpreadConstraints | list | `[]` | TopologySpreadConstraints for scheduling |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
