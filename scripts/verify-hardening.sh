#!/usr/bin/env bash
# Verifica propiedades de hardening declaradas en los metadatos de una imagen.
# Uso: scripts/verify-hardening.sh <imagen:tag>
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <imagen:tag>" >&2
  exit 2
fi

image="$1"
fail=0

user="$(docker image inspect --format '{{.Config.User}}' "$image")"
if [[ "$user" == "10001:10001" ]]; then
  echo "OK    usuario no privilegiado: $user"
else
  echo "FAIL  usuario '$user' (se espera 10001:10001)"
  fail=1
fi

has_hc="$(docker image inspect --format '{{if .Config.Healthcheck}}yes{{else}}no{{end}}' "$image")"
if [[ "$has_hc" == "yes" ]]; then
  echo "OK    healthcheck definido"
else
  echo "FAIL  la imagen no define HEALTHCHECK"
  fail=1
fi

ports="$(docker image inspect --format '{{range $p, $_ := .Config.ExposedPorts}}{{$p}} {{end}}' "$image")"
if [[ -n "${ports// /}" ]]; then
  echo "OK    puertos expuestos: $ports"
else
  echo "FAIL  la imagen no declara EXPOSE"
  fail=1
fi

entry="$(docker image inspect --format '{{json .Config.Entrypoint}}' "$image")"
if [[ "$entry" == *tini* ]]; then
  echo "OK    PID 1 gestionado por tini"
else
  echo "FAIL  el entrypoint no usa tini: $entry"
  fail=1
fi

echo "Nota: read-only rootfs y /tmp en memoria se imponen en runtime (docker-compose.app.yml / Helm)."
exit "$fail"
