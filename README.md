# Cluster API Kamaji vSphere Helm Chart

This Helm chart deploys a Kubernetes cluster on vSphere using Cluster API with Kamaji as the control plane provider. The chart implements a hosted control plane architecture where certain controllers run on the management cluster while providing full integration with vSphere.

## Table of Contents

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
2. Run: `helm upgrade cluster-name ./cluster-api-kamaji-vsphere`
3. Cluster API automatically replaces nodes using the new configuration

### Split Infrastructure Controller Deployment

The chart deploys vSphere controllers on the management cluster instead of the workload cluster.

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
```

This configuration marks the node pool for autoscaling. The Cluster Autoscaler will use these settings to scale the node pool within the specified limits. There are sever criteria for selecting the cluster autoscaler, including labels, cluster name, and namespace. Refer to the [Cluster Autoscaler documentation](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/clusterapi/README.md)

You need to install the Cluster Autoscaler in the management cluster. Here is an example using Helm:

```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
helm upgrade --install ${CLUSTER_NAME}-autoscaler autoscaler/cluster-autoscaler \
    --set cloudProvider=clusterapi \
    --set autoDiscovery.namespace=default \
    --set autoDiscovery.labels[0].foo=bar \
    --set autoDiscovery.clusterName=${CLUSTER_NAME} \
    --set clusterAPIKubeconfigSecret=${CLUSTER_NAME}-kubeconfig \
    --set clusterAPIMode=kubeconfig-incluster
```

This command installs the Cluster Autoscaler and configures it to manage the workload cluster from the management cluster. In the example above, cluster selection is done using the `autoDiscovery` feature, which matches the labels set in the node pool configuration, namespace, and cluster name.

## Prerequisites

- Kamaji installed and configured
- Cluster API vSphere provider installed and configured
- Cluster API IPAM provider installed and configure (optional)
- Access to vSphere environment

## Installation

```bash
# Add repository (if published)
helm repo add clastix https://clastix.github.io/charts
helm repo update

# Install with custom values
helm install cluster-name clastix/capi-kamaji-vsphere -f values.yaml
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
  namespace: cluster-namespace
  labels:
    cluster.x-k8s.io/cluster-name: "cluster-name"
stringData:
  username: "administrator@vsphere.local"
  password: "password"
EOF
```

```yaml
# Create the vsphere-config-secret for Cloud Controller Manager
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: vsphere-config-secret
  namespace: cluster-namespace
  labels:
    cluster.x-k8s.io/cluster-name: "cluster-name"
stringData:
  vsphere.conf: |
    global:
      port: 443
      insecureFlag: true # use for selfsigned certificates
      password: "password"
      user: "administrator@vsphere.local"
    vcenter:
      vcenter.example.com:
        datacenters:
        - "datacenter-name"
        server: "vcenter.example.com"
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
stringData:
  username: "administrator@vsphere.local"
  password: "password"
EOF
```

Deploy a `VSphereClusterIdentity` that references the secret above. The `allowedNamespaces` selector can also be used to control which namespaces are allowed to use the identity:

```yaml
# Create the VSphereClusterIdentity
cat <<EOF | kubectl apply -f -
apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
kind: VSphereClusterIdentity
metadata:
  name: vsphere-cluster-identity
spec:
  secretName: vsphere-secret
  allowedNamespaces:
    selector:
      matchLabels: {} # allow all namespaces
EOF
```

```yaml
# Create the vsphere-config-secret for Cloud Controller Manager
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: vsphere-config-secret
  namespace: cluster-namespace
  labels:
    cluster.x-k8s.io/cluster-name: "cluster-name"
stringData:
  vsphere.conf: |
    global:
      port: 443
      insecureFlag: true # use for selfsigned certificates
      password: "password"
      user: "administrator@vsphere.local"
    vcenter:
      vcenter.example.com:
        datacenters:
        - "datacenter-name"
        server: "vcenter.example.com"
EOF
```

## Usage

### Creating a cluster

```bash
# Deploy using the chart
helm install cluster-name ./cluster-api-kamaji-vsphere -f values.yaml

# Check status
kubectl get cluster,machines

# Get kubeconfig
clusterctl get kubeconfig cluster-name > cluster-name.kubeconfig
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
  image:
    tag: "v1.32.0"


# Apply upgrade
helm upgrade cluster-name ./cluster-api-kamaji-vsphere -f values.yaml

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
helm upgrade cluster-name ./cluster-api-kamaji-vsphere -f values.yaml

# Watch the scaling
kubectl get machines -w
```

### Deleting a cluster

```bash
# Delete the cluster
helm uninstall cluster-name
```

### Troubleshooting

If Helm uninstall fails with IP pool deletion errors:

```bash
# Wait for machines to be deleted first
kubectl delete machinedeployment -l cluster.x-k8s.io/cluster-name=cluster-name
kubectl wait --for=delete vspheremachines -l cluster.x-k8s.io/cluster-name=cluster-name

# Retry helm uninstall
helm uninstall cluster-name
```

If nodes taints are not removed, check Cloud Controller Manager logs:

```bash
# Check CPI Controller logs
kubectl logs -l component=cloud-controller-manager
```

Most of the time the issue is related to authentication issues with vSphere credentials. Check the secret used by the `VSphereClusterIdentity` or `VSphereCluster` and ensure that the credentials are correct.

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
