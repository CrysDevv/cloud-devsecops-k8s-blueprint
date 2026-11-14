# cloud-devsecops-k8s-blueprint

Plantilla estándar de ingeniería de plataforma, despliegue en Kubernetes y seguridad DevSecOps para microservicios **Java 17 (Spring Boot)**, **Node.js 20 (NestJS)** y **Python 3.12 (FastAPI)**.

## Arquitectura General

```mermaid
flowchart LR
    subgraph CI["GitHub Actions DevSecOps Pipeline"]
        direction TB
        T1["1. IaC Lint & Trivy Config<br/>(Terraform + Helm)"]
        T2["2. Unit Tests (>80% Cov)<br/>& SonarQube SAST"]
        T3["3. Build Multi-Stage (UID 10001)<br/>Syft SBOM + Trivy Image"]
        T4["4. DAST Dinámico<br/>(OWASP ZAP Baseline)"]
        T1 --> T2 --> T3 --> T4
    end

    subgraph AWS["AWS Cloud / LocalStack (Terraform)"]
        SNS["SNS Topic<br/>(KMS Encrypted)"]
        SQS["SQS Queue + DLQ<br/>(TLS-Only Policy)"]
        S3["S3 Bucket<br/>(Private + Versioning)"]
        SM["Secrets Manager"]
        SNS --> SQS
    end

    subgraph K8S["Kubernetes Cluster (Helm Zero-Trust)"]
        ING["Ingress Controller"]
        POD["Microservice Pod<br/>UID 10001 | ReadOnly FS | Drop ALL"]
        NP["NetworkPolicy<br/>(Deny-by-Default)"]
        OTEL["OpenTelemetry Collector<br/>(gRPC :4317 / HTTP :4318)"]
        PROM["Prometheus<br/>(Metrics + Alerts)"]
        GRAF["Grafana<br/>(RED/USE Dashboards)"]

        ING -->|HTTP| POD
        NP -.->|Restringe Ingress/Egress| POD
        POD -->|OTLP| OTEL
        OTEL -->|Spanmetrics :8889| PROM
        PROM --> GRAF
    end

    T4 -->|OCI Image + SBOM| POD
    POD <-->|IRSA / IAM Least Privilege| AWS
