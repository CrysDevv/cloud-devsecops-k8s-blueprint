{{/*
Nombre corto del chart.
*/}}
{{- define "microservice-base.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Nombre completo del release (máx. 63 caracteres).
*/}}
{{- define "microservice-base.fullname" -}}
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
Etiqueta chart.
*/}}
{{- define "microservice-base.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Etiquetas selectoras (inmutables).
*/}}
{{- define "microservice-base.selectorLabels" -}}
app.kubernetes.io/name: {{ include "microservice-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Etiquetas comunes.
*/}}
{{- define "microservice-base.labels" -}}
helm.sh/chart: {{ include "microservice-base.chart" . }}
{{ include "microservice-base.selectorLabels" . }}
app.kubernetes.io/version: {{ default .Chart.AppVersion .Values.image.tag | toString | trunc 63 | trimSuffix "-" | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Nombre de la ServiceAccount.
*/}}
{{- define "microservice-base.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "microservice-base.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Imagen: repository es obligatorio; digest tiene prioridad sobre tag.
*/}}
{{- define "microservice-base.image" -}}
{{- $repo := required "image.repository es obligatorio (usa --set image.repository=<registro>/<imagen>)" .Values.image.repository -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" $repo .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" $repo (default .Chart.AppVersion .Values.image.tag) -}}
{{- end -}}
{{- end }}
