#!/usr/bin/env bash
# Construye la imagen endurecida de un microservicio y verifica su hardening.
# Uso: scripts/build-image.sh <java17|node20|python312> <directorio-del-servicio> <imagen:tag>
# Variables opcionales: APP_VERSION, VCS_REF, APP_PORT
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ne 3 ]]; then
  echo "Uso: $0 <java17|node20|python312> <directorio-del-servicio> <imagen:tag>" >&2
  exit 2
fi

profile="$1"
context="$2"
tag="$3"

case "$profile" in
  java17)    dockerfile="$ROOT/docker/Dockerfile.java17" ;;
  node20)    dockerfile="$ROOT/docker/Dockerfile.node20" ;;
  python312) dockerfile="$ROOT/docker/Dockerfile.python312" ;;
  *) echo "Perfil desconocido: $profile (usa java17, node20 o python312)" >&2; exit 2 ;;
esac

if [[ ! -d "$context" ]]; then
  echo "ERROR: el directorio de contexto no existe: $context" >&2
  exit 1
fi

DOCKER_BUILDKIT=1 docker build \
  --file "$dockerfile" \
  --build-arg "APP_VERSION=${APP_VERSION:-0.0.0}" \
  --build-arg "VCS_REF=${VCS_REF:-unknown}" \
  --build-arg "APP_PORT=${APP_PORT:-8080}" \
  --tag "$tag" \
  "$context"

"$ROOT/scripts/verify-hardening.sh" "$tag"
