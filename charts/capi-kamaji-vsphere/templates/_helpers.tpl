{{/* release name */}}
{{- define "cluster-api-kamaji-vsphere.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* cluster name */}}
{{- define "cluster-api-kamaji-vsphere.cluster-name" -}}
{{- default .Release.Name .Values.cluster.name | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/* vSphere secret name used by ClusterAPI */}}
{{- define "cluster-api-kamaji-vsphere.vsphere-secret-name" -}}
{{- if .Values.vSphere.secret.create -}}
{{- printf "%s-vsphere-secret" (include "cluster-api-kamaji-vsphere.cluster-name" .) -}}
{{- else -}}
{{- .Values.vSphere.secret.name | default "vsphere-secret" -}}
{{- end -}}
{{- end -}}

{{/* vSphere config secret name used by CPI */}}
{{- define "cluster-api-kamaji-vsphere.vsphere-config-secret-name" -}}
{{- if .Values.vSphereCloudControllerManager.secret.create -}}
{{- printf "%s-vsphere-config-secret" (include "cluster-api-kamaji-vsphere.cluster-name" .) -}}
{{- else -}}
{{- .Values.vSphereCloudControllerManager.secret.name | default "vsphere-config-secret" -}}
{{- end -}}
{{- end -}}

{{/* CSI vSphere config secret name used by CSI */}}
{{- define "cluster-api-kamaji-vsphere.csi-config-secret-name" -}}
{{- if .Values.vSphereStorageControllerManager.secret.create -}}
{{- printf "%s-csi-config-secret" (include "cluster-api-kamaji-vsphere.cluster-name" .) -}}
{{- else -}}
{{- .Values.vSphereStorageControllerManager.secret.name | default "csi-config-secret" -}}
{{- end -}}
{{- end -}}