{{/* vim: set filetype=mustache: */}}

{{/*
Create a default fully qualified job name.
Due to the job only being allowed to run once, we add the chart revision so helm
upgrades don't cause errors trying to create the already ran job.
Due to the helm delete not cleaning up these jobs, we add a randome value to
reduce collision
*/}}
{{- define "harbor.oidc.jobname" -}}
{{- $name := include "harbor.fullname" . | trunc 50 | trimSuffix "-" -}}
{{- printf "%s-oidc-%d" $name .Release.Revision | trunc 63 | trimSuffix "-" -}}
{{- end -}}
