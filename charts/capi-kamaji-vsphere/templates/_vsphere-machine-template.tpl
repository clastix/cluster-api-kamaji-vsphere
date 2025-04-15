{{- define "vSphereMachineTemplateSpec" -}}
cloneMode: linkedClone
datacenter: {{ .Global.Values.vSphere.dataCenter | quote }}
datastore: {{ .nodePool.dataStore | quote }}
folder: {{ .nodePool.folder | quote }}
diskGiB: {{ .nodePool.diskGiB }}
memoryMiB: {{ .nodePool.memoryMiB }}
numCPUs: {{ .nodePool.numCPUs }}
os: Linux
network:
  devices:
  - dhcp4: {{ .nodePool.dhcp4 }}
    nameservers:
    {{- range .nodePool.nameServers }}
    - {{ . | quote }}
    {{- end }}
    addressesFromPools:
    {{- if .nodePool.addressesFromPools.enabled }}
    - apiGroup: ipam.cluster.x-k8s.io
      kind: InClusterIPPool
      name: {{ include "cluster-api-kamaji-vsphere.cluster-name" .Global | quote}}
    {{- end }}
    networkName: {{ .nodePool.network | quote }}
    {{- if .nodePool.staticRoutes }}
    routes:
    {{- range .nodePool.staticRoutes }}
    - to: {{ .to | quote }}
      via: {{ .via | quote }}
      metric: {{ .metric | default 100 }}
    {{- end }}
    {{- end }}
powerOffMode: trySoft
resourcePool: {{ .nodePool.resourcePool | quote }}
server: {{ .Global.Values.vSphere.server | quote }}
storagePolicyName: {{ .nodePool.storagePolicyName | quote }}
template: {{ .nodePool.template | quote }}
thumbprint: {{ .Global.Values.vSphere.tlsThumbprint | quote }}
{{- end -}}

{{/*
Calculates a SHA256 hash of the VSphereMachineTemplate content.
*/}}

{{- define "vSphereMachineTemplateHash" -}}
{{- $templateContent := include "vSphereMachineTemplateSpec" . -}}
{{- $templateContent | sha256sum | trunc 8 -}}
{{- end -}}