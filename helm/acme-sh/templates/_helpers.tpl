{{/*
Expand the name of the chart.
*/}}
{{- define "acme-sh.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "acme-sh.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "acme-sh.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "acme-sh.labels" -}}
helm.sh/chart: {{ include "acme-sh.chart" . }}
{{ include "acme-sh.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "acme-sh.selectorLabels" -}}
app.kubernetes.io/name: {{ include "acme-sh.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "acme-sh.serviceAccountName" -}}
{{- default (include "acme-sh.fullname" .) .Values.serviceAccount.name }}
{{- end }}

{{/*
Set paths for volumes
*/}}
{{- define "acme-sh.sslStorage" -}}
{{ .Values.global.storageRoot }}/persist/ssl
{{- end}}
{{- define "acme-sh.internalStorage" -}}
{{ .Values.global.storageRoot }}/persist/acme.sh
{{- end}}


{{- define "acme-sh.secretName" -}}
{{- if .Values.secrets.nameOverride }}
{{- .Values.secrets.nameOverride }}
{{- else }}
{{- include "acme-sh.fullname" . }}
{{- end }}
{{- end }}