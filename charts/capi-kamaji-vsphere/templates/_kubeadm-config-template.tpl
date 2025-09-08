{{- define "kubeadmConfigTemplateSpec" -}}
joinConfiguration:
  nodeRegistration:
    criSocket: /var/run/containerd/containerd.sock
    kubeletExtraArgs:
      node-ip: "{{`{{ ds.meta_data.local_ipv4 }}`}}"
      cloud-provider: external
      {{- if and .nodePool (hasKey .nodePool "labels") }}
      node-labels: {{ .nodePool.labels | quote }}
      {{- end }}
      {{- if and .nodePool (hasKey .nodePool "taints") }}
      register-with-taints: {{ .nodePool.taints | quote }}
      {{- end }}
    name: "{{`{{ local_hostname }}`}}"
{{- if .nodePool.preKubeadmCommands }}
preKubeadmCommands:
{{- range .nodePool.preKubeadmCommands }}
  - {{- toYaml . | nindent 4 }}
{{- end }}
{{- end }}
{{- if .nodePool.postKubeadmCommands }}
postKubeadmCommands:
{{- range .nodePool.postKubeadmCommands }}
  - {{- toYaml . | nindent 4 }}
{{- end }}
{{- end }}
{{- if .nodePool.additionalCloudInitFiles }}
files:
- path: "/etc/cloud/cloud.cfg.d/99-custom.cfg"
  content: {{ .nodePool.additionalCloudInitFiles | quote }}
  owner: "root:root"
  permissions: "0644"
{{- end }}
{{- if .nodePool.users }}
users:
{{- range .nodePool.users }}
  - {{- toYaml . | nindent 4 }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Calculates a SHA256 hash of the kubeadmConfigTemplate content.
*/}}

{{- define "kubeadmConfigTemplateHash" -}}
{{- $templateContent := include "kubeadmConfigTemplateSpec" . -}}
{{- $templateContent | sha256sum | trunc 8 -}}
{{- end -}}