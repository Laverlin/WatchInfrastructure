{{/*
Expand the name of the chart.
*/}}
{{- define "watch-yas.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "watch-yas.fullname" -}}
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
{{- define "watch-yas.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "watch-yas-processor.labels" -}}
helm.sh/chart: {{ include "watch-yas.chart" . }}
{{ include "watch-yas-processor.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "watch-yas-restapi.labels" -}}
helm.sh/chart: {{ include "watch-yas.chart" . }}
{{ include "watch-yas-restapi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "watch-yas-bot.labels" -}}
helm.sh/chart: {{ include "watch-yas.chart" . }}
{{ include "watch-yas-bot.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "watch-yas-processor.selectorLabels" -}}
app.kubernetes.io/name: {{ include "watch-yas.name" . }}-processor
app.kubernetes.io/instance: {{ .Release.Name }}-processor
{{- end }}

{{- define "watch-yas-restapi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "watch-yas.name" . }}-restapi
app.kubernetes.io/instance: {{ .Release.Name }}-restapi
{{- end }}

{{- define "watch-yas-bot.selectorLabels" -}}
app.kubernetes.io/name: {{ include "watch-yas.name" . }}-bot
app.kubernetes.io/instance: {{ .Release.Name }}-bot
{{- end }}

{{- define "otelUrlWithHttp" -}}
{{- printf "%s://%s:%d" .Values.otelCollectorEndpoint.scheme .Values.otelCollectorEndpoint.url ( .Values.otelCollectorEndpoint.port | int ) }}
{{- end }}

{{- define "otelUrl" -}}
{{- printf "%s:%d" .Values.otelCollectorEndpoint.url ( .Values.otelCollectorEndpoint.port | int )}}
{{- end }}