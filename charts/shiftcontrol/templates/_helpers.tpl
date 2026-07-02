{{- define "shiftcontrol.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "shiftcontrol.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "shiftcontrol.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "shiftcontrol.labels" -}}
helm.sh/chart: {{ include "shiftcontrol.chart" . }}
app.kubernetes.io/name: {{ include "shiftcontrol.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "shiftcontrol.selectorLabels" -}}
app.kubernetes.io/name: {{ include "shiftcontrol.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "shiftcontrol.componentLabels" -}}
{{ include "shiftcontrol.labels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "shiftcontrol.componentSelectorLabels" -}}
{{ include "shiftcontrol.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "shiftcontrol.componentFullname" -}}
{{- printf "%s-%s" (include "shiftcontrol.fullname" .root) .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "shiftcontrol.secretName" -}}
{{- if .Values.existingSecret -}}
{{- .Values.existingSecret -}}
{{- else -}}
{{- printf "%s-secrets" (include "shiftcontrol.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "shiftcontrol.publicBaseUrl" -}}
{{- printf "%s://%s" .Values.global.scheme .Values.global.domain -}}
{{- end -}}

{{- define "shiftcontrol.podSecurityContext" -}}
{{- $global := deepCopy (default dict .root.Values.global.podSecurityContext) -}}
{{- $component := default dict .componentSecurityContext -}}
{{- $merged := mergeOverwrite $global $component -}}
{{- if not (empty $merged) -}}
{{- toYaml $merged -}}
{{- end -}}
{{- end -}}

{{- define "shiftcontrol.containerSecurityContext" -}}
{{- $global := deepCopy (default dict .root.Values.global.containerSecurityContext) -}}
{{- $component := default dict .componentSecurityContext -}}
{{- $merged := mergeOverwrite $global $component -}}
{{- if not (empty $merged) -}}
{{- toYaml $merged -}}
{{- end -}}
{{- end -}}

{{- define "shiftcontrol.validateValues" -}}
{{- if not .Values.existingSecret }}
  {{- if not .Values.global.internalApiKey }}
    {{- fail "global.internalApiKey is required unless existingSecret is set" }}
  {{- end }}
  {{- if not .Values.postgres.auth.password }}
    {{- fail "postgres.auth.password is required unless existingSecret is set" }}
  {{- end }}
  {{- if not .Values.rabbitmq.auth.password }}
    {{- fail "rabbitmq.auth.password is required unless existingSecret is set" }}
  {{- end }}
  {{- if and .Values.pgadmin.enabled (not .Values.pgadmin.credentials.password) }}
    {{- fail "pgadmin.credentials.password is required when pgadmin.enabled=true unless existingSecret is set" }}
  {{- end }}
{{- end }}
{{- if and .Values.notificationIngress.enabled .Values.notificationIngress.host (empty .Values.notificationIngress.tls) }}
  {{- fail "notificationIngress.tls must be set when notificationIngress.host overrides global.domain" }}
{{- end }}
{{- end -}}
