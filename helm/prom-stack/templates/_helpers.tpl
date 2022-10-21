{{/*
Expand the name of the chart.
*/}}
{{- define "prom-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "prom-stack.fullname" -}}
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
{{- define "prom-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "prom-stack.labels" -}}
helm.sh/chart: {{ include "prom-stack.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "prometheus.labels" -}}
{{ include "prom-stack.labels" . }}
{{ include "prometheus.selectorLabels" . }}
{{- end }}

{{- define "nodeExporter.labels" -}}
{{ include "prom-stack.labels" . }}
{{ include "nodeExporter.selectorLabels" . }}
{{- end }}

{{- define "kubeStateMetrics.labels" -}}
{{ include "prom-stack.labels" . }}
{{ include "kubeStateMetrics.selectorLabels" . }}
{{- end }}

{{- define "grafana.labels" -}}
{{ include "prom-stack.labels" . }}
{{ include "grafana.selectorLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "prometheus.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.prometheus.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "nodeExporter.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.nodeExporter.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "kubeStateMetrics.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.kubeStateMetrics.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "grafana.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.grafana.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "prometheus.serviceAccountName" -}}
{{- default .Values.prometheus.name .Values.prometheus.serviceAccountName }}
{{- end }}

{{- define "kubeStateMetrics.serviceAccountName" -}}
{{- default .Values.kubeStateMetrics.name .Values.kubeStateMetrics.serviceAccountName }}
{{- end }}

