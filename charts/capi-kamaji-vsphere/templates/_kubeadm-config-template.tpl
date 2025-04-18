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
preKubeadmCommands:
- hostnamectl set-hostname "{{`{{ ds.meta_data.hostname }}`}}"
- echo "::1         ipv6-localhost ipv6-loopback localhost6 localhost6.localdomain6" >/etc/hosts
- echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" >>/etc/hosts
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
- name: {{ .name | quote }}
  sshAuthorizedKeys:
  {{- range .sshAuthorizedKeys }}
  - {{ . | quote }}
  {{- end }}
  sudo: {{ .sudo | quote }}
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