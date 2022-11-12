{{/*
Expand the name of the chart.
*/}}
{{- define "watch-micro.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "watch-micro.fullname" -}}
{{- $top := index . 0 -}}
{{- $suffix := index . 1 -}}
{{- if $top.Values.fullnameOverride }}
{{- $top.Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default $top.Chart.Name $top.Values.nameOverride }}
{{- if contains $name $top.Release.Name }}
{{- printf "%s-%s" $top.Release.Name $suffix | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-%s" $top.Release.Name $name $suffix | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "watch-micro.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "watch-micro.labels" -}}
{{- $top := index . 0 -}}
{{- $suffix := index . 1 -}}
{{ include "watch-micro.selectorLabels" (list $top $suffix) }}
helm.sh/chart: {{ include "watch-micro.chart" $top }}
{{- if $top.Chart.AppVersion }}
app.kubernetes.io/version: {{ $top.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $top.Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "watch-micro.selectorLabels" -}}
{{- $top := index . 0 -}}
{{- $suffix := index . 1 -}}
app.kubernetes.io/name: {{- printf " %s-%s" (include "watch-micro.name" $top) $suffix }}
app.kubernetes.io/instance: {{ $top.Release.Name }}
{{- end }}


