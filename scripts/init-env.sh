#!/usr/bin/env bash
# Genera .env desde .env.example con una contraseña aleatoria para Grafana.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ -f .env ]]; then
  echo ".env ya existe; no se sobrescribe."
  exit 0
fi

command -v openssl >/dev/null 2>&1 || { echo "ERROR: se requiere openssl." >&2; exit 1; }

umask 077
grep -v '^GRAFANA_ADMIN_PASSWORD=' .env.example > .env
printf 'GRAFANA_ADMIN_PASSWORD=%s\n' "$(openssl rand -base64 24 | tr -d '/+=\n')" >> .env

echo ".env creado (permisos 600). Usuario Grafana: admin. La contraseña está en .env."
