# Cluster API Kamaji vSphere Helm Chart

This Helm chart deploys a Kubernetes cluster on vSphere using Cluster API with Kamaji as the control plane provider. The chart implements a hosted control plane architecture where certain controllers run on the management cluster while providing full integration with vSphere.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Key Features](#key-features)
  - [Automatic Rolling Updates](#automatic-rolling-updates)
  - [Split Infrastructure Controller Deployment](#split-infrastructure-controller-deployment)
  - [Cluster Autoscaler Integration](#cluster-autoscaler-integration)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Secret Management](#secret-management)
  - [Create Cluster API Secret](#create-cluster-api-secret)
  - [Create Cloud Controller Manager Secret](#create-cloud-controller-manager-secret)
  - [Create CSI Controller Secret](#create-csi-controller-secret)
- [Usage](#usage)
  - [Creating a cluster](#creating-a-cluster)
  - [Upgrading a cluster](#upgrading-a-cluster)
  - [Scaling a cluster](#scaling-a-cluster)
  - [Deleting a cluster](#deleting-a-cluster)
  - [Troubleshooting](#troubleshooting)
- [Configuration](#configuration)
- [License](#license)

## Architecture Overview

The chart implements a **Split Architecture** where:

1. The Kubernetes control plane runs as containers on the management cluster (Kamaji)
2. The Cloud Controller Manager (CPI) and CSI Storage Controller run on the management cluster
3. Worker nodes run CSI Node drivers on the workload cluster
4. Communication between components happens via the Kubernetes API server

This approach provides security benefits by isolating vSphere credentials from tenant users while maintaining full Cluster API integration.

## Key Features

### Automatic Rolling Updates

The chart supports seamless rolling updates of the entire cluster when configuration changes. This works through Cluster API's machine lifecycle management for:

- Physical machine parameter changes, e.g. CPU, memory, disk
- Kubernetes version upgrades
- vSphere template changes
- `cloud-init` configuration updates

The implementation uses hash-suffixed templates, `VSphereMachineTemplate` and `KubeadmConfigTemplate` that:
1. Generate a new template with updated configuration and unique name on `helm upgrade`
2. Update references in `MachineDeployment` to the new template
3. Trigger Cluster API's built-in rolling update process

#### Rolling Update Workflow

1. Update `values.yaml` with new configuration
2. Run: `helm upgrade my-cluster ./cluster-api-kamaji-vsphere`
3. Cluster API automatically replaces nodes using the new configuration

### Split Infrastructure Controller Deployment

The chart deploys vSphere infrastructure controllers on the management cluster instead of the workload cluster:

- **Cloud Controller Manager (CPI)**: Runs on the management cluster with access to the hosted tenant's API server
- **vSphere CSI Controller**: Runs on the management cluster
- **CSI Node Drivers**: Deployed on workload cluster nodes via `ClusterResourceSet`

This architecture enables:
- Tenant isolation from vSphere credentials
- Simplified networking requirements
- Centralized controller management

### Cluster Autoscaler Integration

The chart includes support for enabling the Cluster Autoscaler for each node pool. This feature allows you to mark node pool machines to be autoscaled. However, you still need to install the Cluster Autoscaler separately.

The Cluster Autoscaler runs in the management cluster, following the hosted control plane model, and manages the scaling of the workload cluster. To enable autoscaling for a node pool, set the `autoscaling.enabled` field to `true` in your `values.yaml` file:

```yaml
nodePools:
  - name: default
    replicas: 3
    autoscaling:
      enabled: true
      minSize: 2
      maxSize: 6
      labels:
        autoscaling: "enabled"
```

This configuration marks the node pool for autoscaling. The Cluster Autoscaler will use these settings to scale the node pool within the specified limits.

You need to install the Cluster Autoscaler in the management cluster. Here is an example using Helm:

```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
helm upgrade --install ${CLUSTER_NAME}-autoscaler autoscaler/cluster-autoscaler \
    --set cloudProvider=clusterapi \
    --set autodiscovery.namespace=default \
    --set "autoDiscovery.labels[0].autoscaling=enabled" \
    --set clusterAPIKubeconfigSecret=${CLUSTER_NAME}-kubeconfig \
    --set clusterAPIMode=kubeconfig-incluster
```

This command installs the Cluster Autoscaler and configures it to manage the workload cluster from the management cluster.

## Prerequisites

- Kubernetes 1.28+
- Kamaji installed and configured
- Cluster API with vSphere provider
- IPAM provider (optional)
- Helm 3.x
- Access to vSphere environment

## Installation

```bash
# Add repository (if published)
helm repo add clastix https://clastix.github.io/charts
helm repo update

# Install with custom values
helm install my-cluster clastix/capi-kamaji-vsphere -f my-values.yaml
```

## Secret Management

The chart requires three distinct vSphere access secrets:

1. **Cluster API Secret** (default name `vsphere-secret`)
   - Used by Cluster API to provision VMs
   - Contains vSphere credentials for infrastructure operations

2. **Cloud Controller Manager Secret** (default name `vsphere-config-secret`)
   - Used by the vSphere Cloud Provider Interface
   - Contains configuration for vCenter

3. **CSI Controller Secret** (default name `csi-config-secret`)
   - Used by the Storage Controller Manager
   - Enables volume provisioning and attachment

You can leave the chart to create these secrets or reference existing ones:

```yaml
# Using existing secrets
vsphere:
  secret:
    create: false
    name: vsphere-secret

vSphereCloudControllerManager:
  secret:
    create: false
    name: vsphere-config-secret

vSphereStorageControllerManager:
  secret:
    create: false
    name: csi-config-secret
```

### Create Cluster API Secret

```bash
# Create the vsphere-secret for Cluster API
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: vsphere-secret
  labels:
    cluster.x-k8s.io/cluster-name: "my-cluster"
stringData:
  username: "administrator@vsphere.local"
  password: "YOUR_PASSWORD"
EOF
```

### Create Cloud Controller Manager Secret

```bash
# Create the vsphere-config-secret for Cloud Controller Manager
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: vsphere-config-secret
  labels:
    cluster.x-k8s.io/cluster-name: "my-cluster"
stringData:
  vsphere.conf: |
    global:
      port: 443
      insecure-flag: false
      password: "YOUR_PASSWORD"
      user: "administrator@vsphere.local"
      thumbprint: "YOUR_VCENTER_THUMBPRINT"
    vcenter:
      vcenter.example.com:
        datacenters:
        - "YOUR_DATACENTER"
        server: "vcenter.example.com"
EOF
```

### Create CSI Controller Secret

```bash
# Create the csi-config-secret for Storage Controller
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: csi-config-secret
  labels:
    cluster.x-k8s.io/cluster-name: "my-cluster"
stringData:
  csi-vsphere.conf: |
    [Global]
    cluster-id = "namespace/my-cluster"
    thumbprint = "YOUR_VCENTER_THUMBPRINT"
    insecure-flag = false
    [VirtualCenter "vcenter.example.com"]
    user        = "administrator@vsphere.local"
    password    = "YOUR_PASSWORD"
    datacenters = "YOUR_DATACENTER"
EOF
```

## Usage

### Creating a cluster

```bash
# Deploy using the chart
helm install my-cluster ./cluster-api-kamaji-vsphere -f values.yaml

# Check status
kubectl get cluster,machines

# Get kubeconfig
clusterctl get kubeconfig my-cluster > my-cluster.kubeconfig
```

### Upgrading a cluster

```bash
# Update values.yaml
cluster:
  version: "v1.32.0"
nodePools:
  - name: default
    template: "ubuntu-2204-kube-v1.32.0"
vSphereCloudControllerManager:
  version: "v1.32.0"

# Apply upgrade
helm upgrade my-cluster ./cluster-api-kamaji-vsphere -f values.yaml

# Watch the rolling update
kubectl get machines -w
```

### Scaling a cluster

```bash
# Update values.yaml
nodePools:
  - name: default
    replicas: 5

# Apply scaling
helm upgrade my-cluster ./cluster-api-kamaji-vsphere -f values.yaml

# Watch the scaling
kubectl get machines -w
```

### Deleting a cluster

```bash
# Delete the cluster
helm uninstall my-cluster
```

### Troubleshooting

If Helm uninstall fails with IP pool deletion errors:

```bash
# Wait for machines to be deleted first
kubectl delete machinedeployment -l cluster.x-k8s.io/cluster-name=my-cluster
kubectl wait --for=delete vspheremachines -l cluster.x-k8s.io/cluster-name=my-cluster

# Retry helm uninstall
helm uninstall my-cluster
```

If nodes taints are not removed:

```bash
# Check CPI Controller logs
kubectl logs -l component=cloud-controller-manager
```

If volume provisioning fails:

```bash
# Check CSI Controller logs
kubectl logs -l component=csi-controller-manager
```

## Configuration

Here the values you can override:

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

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Clastix Labs | <authors@clastix.labs> |  |

## Source Code

* <https://github.com/clastix/cluster-api-kamaji-vsphere>

## License

This project is licensed under the Apache2 License. See the LICENSE file for more details.