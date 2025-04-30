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
- [Credentials Management](#credentials-management)
  - [Credentials through Secrets](#credentials-through-secrets)
  - [Credentials through VSphereClusterIdentity](#credentials-through-vsphereclusteridentity)
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

## Credentials Management

Cluster API Provider vSphere (CAPV) supports multiple methods to provide vCenter credentials and authorize  clusters to use them:

- **Secrets**: credentials are provided via `secret` used by `VSphereCluster`. This will create a unique relationship between the `VSphereCluster` and `secret` and the `secret` cannot be utilized by other clusters.

- **VSphereClusterIdentity**: credentials are provided via `VSphereClusterIdentity`, a cluster scoped resource and enables multiple `VSphereClusters` to share the same set of credentials. The namespaces that are allowed to use the `VSphereClusterIdentity` can also be configured via a `LabelSelector`.

More details on the CAPV documentation: [Cluster API Provider vSphere](https://github.com/kubernetes-sigs/cluster-api-provider-vsphere)

### Credentials through Secrets
The chart creates three secrets by default, one for each component that requires vSphere credentials. These secrets are created in the same namespace as the `Cluster` resource and are labeled with the cluster name:

```yaml
# Create the vsphere-secret for Cluster API
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: vsphere-secret
  namespace: my-cluster
  labels:
    cluster.x-k8s.io/cluster-name: "my-cluster"
stringData:
  username: "administrator@vsphere.local"
  password: "YOUR_PASSWORD"
EOF
```

```yaml
# Create the vsphere-config-secret for Cloud Controller Manager
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: vsphere-config-secret
  namespace: my-cluster
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

```yaml
# Create the csi-config-secret for Storage Controller
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: csi-config-secret
  namespace: my-cluster
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

### Credentials through VSphereClusterIdentity
The chart can also be configured to use `VSphereClusterIdentity` for managing vSphere credentials. This allows multiple clusters to share the same credentials.

Deploy a secret with the credentials in the CAPV manager namespace (capv-system by default):

```yaml
# Create the vsphere-secret for Cluster API
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: vsphere-secret
  namespace: capv-system
  labels:
    cluster.x-k8s.io/cluster-name: "my-cluster"
stringData:
  username: "administrator@vsphere.local"
  password: "YOUR_PASSWORD"
EOF
```

Deploy a `VSphereClusterIdentity` that references the secret above. The `allowedNamespaces` selector can also be used to control which namespaces are allowed to use the identity:

```yaml
# Create the VSphereClusterIdentity
cat <<EOF | kubectl apply -f -
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha3
kind: VSphereClusterIdentity
metadata:
  name: vsphere-cluster-identity
spec:
  secretName: vsphere-secret
  allowedNamespaces:
    selector:
      matchLabels: {} # allow all namespaces
```

> **Note**: The CSI secret and the Cloud Controller Manager secret must still be created separately.

```yaml
# Create the vsphere-config-secret for Cloud Controller Manager
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: vsphere-config-secret
  namespace: my-cluster
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

```yaml
# Create the csi-config-secret for Storage Controller
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: csi-config-secret
  namespace: my-cluster
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

See the values you can override [here](charts/capi-kamaji-vsphere/README.md).

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Clastix Labs | <authors@clastix.labs> |  |

## Source Code

* <https://github.com/clastix/cluster-api-kamaji-vsphere>

## License

This project is licensed under the Apache2 License. See the LICENSE file for more details.
