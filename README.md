# cloud-devsecops-k8s-blueprint

Plantilla estándar de infraestructura, despliegue y seguridad para microservicios
Java 17 (Spring Boot), Node.js 20 (NestJS) y Python 3.12 (FastAPI).

> Estado: Fase 1 (contenedores endurecidos y stack local). Terraform/Helm llegan en la
> Fase 2; pipeline DevSecOps, dashboards completos y ADRs en la Fase 3.

## Requisitos

Docker Engine 24+ con BuildKit y Docker Compose v2. `openssl` para `scripts/init-env.sh`.

## Stack local

```bash
./scripts/init-env.sh            # genera .env con contraseña aleatoria de Grafana
docker compose up -d
docker compose ps
```

| Servicio | URL (solo loopback) |
|---|---|
| LocalStack (SQS, SNS, S3, Secrets Manager) | http://127.0.0.1:4566 |
| OTLP gRPC / HTTP (OpenTelemetry Collector) | 127.0.0.1:4317 / 127.0.0.1:4318 |
| Prometheus | http://127.0.0.1:9090 |
| Grafana (usuario `admin`, clave en `.env`) | http://127.0.0.1:3000 |

Grafana carga automáticamente el datasource Prometheus y el dashboard "Stack Health".

## Construir la imagen de un microservicio

```bash
./scripts/build-image.sh java17    ../mi-servicio-java   mi-servicio-java:dev
./scripts/build-image.sh node20    ../mi-servicio-nest   mi-servicio-nest:dev
./scripts/build-image.sh python312 ../mi-servicio-api    mi-servicio-api:dev
```

El script construye con BuildKit y verifica usuario 10001, HEALTHCHECK, EXPOSE y tini.

## Ejecutar un microservicio con el runtime endurecido

```bash
APP_IMAGE=mi-servicio-api:dev docker compose -f docker-compose.yml -f docker-compose.app.yml up -d
```

El override impone: usuario 10001, `read_only: true`, `/tmp` en tmpfs, `cap_drop: ALL`,
`no-new-privileges`, límites de CPU/memoria/PIDs, y variables de OTel y LocalStack.

## Contrato que debe cumplir cada microservicio

- Escuchar en `0.0.0.0` en el puerto `APP_PORT` (por defecto 8080).
- Exponer salud en `/actuator/health` (Java) o `/health` (Node y Python).
- No escribir fuera de `/tmp` (el rootfs es de solo lectura).
- Java: `pom.xml` Maven y Actuator. Node: `package-lock.json` y `npm run build` que genere `dist/main.js`.
  Python: `requirements.txt` con `uvicorn` y dependencias disponibles como wheels.

## Excepciones de hardening documentadas

- LocalStack corre como root y sin rootfs read-only (solo uso local; puertos en loopback).
- El collector de OTel es una imagen `scratch` sin shell, por lo que no tiene healthcheck interno.
