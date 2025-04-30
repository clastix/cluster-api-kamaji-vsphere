{{/* release name */}}
{{- define "cluster-api-kamaji-vsphere.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* cluster name */}}
{{- define "cluster-api-kamaji-vsphere.cluster-name" -}}
{{- default .Release.Name .Values.cluster.name | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/* vSphere config secret name used by CPI */}}
{{- define "cluster-api-kamaji-vsphere.vsphere-config-secret-name" -}}
{{- .Values.vSphereCloudControllerManager.secret.name | default "vsphere-config-secret" -}}
{{- end -}}

{{/* CSI vSphere config secret name used by CSI */}}
{{- define "cluster-api-kamaji-vsphere.csi-config-secret-name" -}}
{{- .Values.vSphereStorageControllerManager.secret.name | default "csi-config-secret" -}}
{{- end -}}
