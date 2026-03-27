{{- define "iframely.fullname" -}}
{{- .Release.Name }}-iframely
{{- end }}

{{- define "iframely.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{ include "iframely.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "iframely.selectorLabels" -}}
app.kubernetes.io/name: iframely
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
