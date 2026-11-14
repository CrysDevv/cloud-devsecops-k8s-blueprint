# ADR-001: Endurecimiento de Contenedores y Seguridad Zero-Trust en Kubernetes

* **Estado:** Aceptado
* **Fecha:** 2026-11-14
* **Contexto:** Plataforma estándar `cloud-devsecops-k8s-blueprint` para microservicios Java 17 (Spring Boot), Node.js 20 (NestJS) y Python 3.12 (FastAPI).

## Contexto y Problema

Los microservicios empresariales suelen desplegarse con imágenes base genéricas que incluyen gestores de paquetes (`apk`, `apt`, `npm`, `pip`), shells interactivos, procesos ejecutándose como `root` (UID 0) y sistemas de archivos escribibles. Dentro de un clúster Kubernetes compartido, una vulnerabilidad de ejecución remota de código (RCE) o SSRF en un servicio permitiría:

1. Modificar binarios o inyectar scripts maliciosos en el sistema de archivos del contenedor.
2. Escalar privilegios hacia el nodo anfitrión mediante capacidades Linux heredadas o `allowPrivilegeEscalation`.
3. Pivotar lateralmente hacia otros pods o hacia el plano de control de Kubernetes mediante el token montado por defecto en `/var/run/secrets/kubernetes.io/serviceaccount`.

## Decisión

Se imponen controles obligatorios en tres capas (Build, Runtime y Red) aplicados de forma uniforme a los tres runtimes soportados:

### 1. Capa de Construcción (Dockerfiles Multi-Stage)
* **Separación Build / Runtime:** Compiladores (`maven`, `tsc`, `gcc`), gestores de paquetes (`npm`, `pip`, `setuptools`, `wheel`) y cachés se eliminan por completo antes de generar la imagen final.
* **Identidad Inmutable (UID/GID `10001`):** Se crea explícitamente el usuario `app` (`10001:10001`) sin shell de inicio de sesión (`/sbin/nologin`). Nunca se utiliza UID `0` ni el usuario genérico `node` (`1000`), evitando colisiones con usuarios del host.
* **Gestión de señales con `tini`:** Todo contenedor arranca bajo `/sbin/tini` o `/usr/bin/tini` como `PID 1` para evitar procesos huérfanos/zombis y propagar correctamente `SIGTERM` durante los *rolling updates*.
* **Healthchecks nativos:** Cada imagen define su propio `HEALTHCHECK` usando binarios mínimos ya presentes (`wget`, `node fetch`, `python urllib`) sin instalar `curl` adicional.

### 2. Capa de Ejecución en Kubernetes (Pod & Container SecurityContext)
* **`readOnlyRootFilesystem: true`:** El sistema de archivos raíz es estrictamente inmutable en tiempo de ejecución. Se monta un volumen `emptyDir` en memoria (`medium: Memory`) exclusivamente en `/tmp` con cuota acotada (`64Mi`–`128Mi`).
* **Eliminación total de capacidades (`capabilities.drop: ["ALL"]`):** Se retiran todas las capacidades POSIX de Linux y se bloquea `allowPrivilegeEscalation: false` junto con `seccompProfile: RuntimeDefault`.
* **Aislamiento de API de Kubernetes:** `automountServiceAccountToken: false` tanto en la `ServiceAccount` como en el `PodSpec`. La autenticación hacia AWS (SQS, SNS, S3, Secrets Manager) se realiza mediante **IRSA** (IAM Roles for Service Accounts) con políticas de mínimo privilegio generadas por Terraform.

### 3. Capa de Red (NetworkPolicy Zero-Trust Deny-by-Default)
* Todo pod queda aislado por defecto para tráfico `Ingress` y `Egress`.
* **Ingress:** Solo se permite tráfico TCP hacia el puerto nombrado `http` proveniente del namespace del Ingress Controller (`ingress-nginx`) y de los pods explícitamente autorizados en `networkPolicy.ingress.fromPods`.
* **Egress:** Solo se autoriza resolución DNS (`kube-dns` puerto 53 UDP/TCP), envío de telemetría OTLP al OpenTelemetry Collector (`observability` puertos 4317/4318) y rangos CIDR explícitos (por ejemplo VPC Endpoints de AWS en el puerto 443).

## Consecuencias

### Positivas
* Reducción drástica de la superficie de ataque en runtime (imposibilidad de descargar malware con `curl`/`pip`/`npm` o persistir binarios en disco).
* Cumplimiento directo con el perfil **Restricted** de Kubernetes Pod Security Standards (PSS) y controles CIS Kubernetes Benchmark.
* Bloqueo efectivo de movimientos laterales en caso de compromiso de un microservicio.

### Trade-offs y Requisitos Operativos
* **Inmutabilidad de disco:** Ningún microservicio puede escribir logs, cachés o archivos temporales fuera de `/tmp`. Los logs deben emitirse exclusivamente por `stdout`/`stderr` en formato estructurado JSON.
* **Dependencias nativas en Python:** Al no incluir compiladores en la imagen `python312`, todas las dependencias en `requirements.txt` deben distribuirse como *wheels* precompilados compatibles con `linux/amd64` o `linux/arm64`.
* **Excepción local documentada:** En el entorno de desarrollo (`docker-compose.yml`), LocalStack se ejecuta como `root` y sin `read_only` debido a sus escrituras internas, mitigado mediante enlace exclusivo a `127.0.0.1`, límites de memoria/PIDs y `no-new-privileges:true`.
