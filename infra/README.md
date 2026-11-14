# infra/

Infraestructura cloud (Terraform) y despliegue en Kubernetes (Helm) de la plantilla.

## Terraform (`infra/terraform`)

Un único conjunto de archivos funciona contra **AWS real** o **LocalStack** mediante la
variable `use_localstack`.

| Módulo | Recursos |
|---|---|
| `modules/messaging` | SNS (cifrado KMS) -> SQS con DLQ, redrive, long polling, SSE-SQS, política que solo acepta el tópico y exige TLS |
| `modules/storage` | S3 con bloqueo de acceso público, BucketOwnerEnforced, versionado, cifrado, lifecycle y política TLS-only |
| `modules/secrets` | Secrets Manager (valor inicial opcional) |

El raíz además calcula una política IAM de mínimo privilegio (`service_iam_policy_json`) y las
variables de entorno para la app (`app_environment`).

### Contra LocalStack (stack de la Fase 1)

```bash
docker compose up -d                      # desde la raíz del repo
cd infra/terraform
terraform init
terraform plan  -var-file=environments/localstack.tfvars.example
terraform apply -var-file=environments/localstack.tfvars.example
terraform output -json app_environment
```

### Contra AWS real

```bash
cd infra/terraform
cp environments/aws.tfvars.example environments/aws.tfvars   # ajusta valores; *.tfvars está en .gitignore
terraform init
terraform plan  -var-file=environments/aws.tfvars
terraform apply -var-file=environments/aws.tfvars
```

Notas:

- Usa un backend remoto cifrado (por ejemplo S3 con bloqueo) en entornos reales: si usas
  `create_initial_secret_version`, los valores quedan en el state.
- Versiona `.terraform.lock.hcl` tras el primer `terraform init`.
- Si usas claves KMS propias (SQS, S3 o Secrets Manager), añade a la política del servicio los permisos
  `kms:Decrypt` y `kms:GenerateDataKey` sobre esas claves.
- SNS con la clave administrada `alias/aws/sns` no admite publicadores de otros servicios (por ejemplo
  CloudWatch o S3). Para ese caso usa una clave gestionada por ti.

## Helm (`infra/helm/microservice-base`)

Chart base para los tres runtimes (Java, Node y Python): Deployment, Service, HPA (v2), PDB,
Ingress (opcional) y NetworkPolicy restrictiva.

Garantías por defecto: UID 10001, `runAsNonRoot`, rootfs de solo lectura, `/tmp` en memoria,
`capabilities: drop ALL`, `seccomp: RuntimeDefault`, sin token de ServiceAccount montado, probes
(startup/readiness/liveness), `preStop` con espera, reparto de réplicas por zona y nodo.

```bash
cd infra/helm/microservice-base
helm lint . -f ci/ci-values.yaml
helm template demo . -f ci/ci-values.yaml | kubeconform -strict -summary   # kubeconform es opcional

helm upgrade --install demo . \
  --namespace demo --create-namespace \
  --set image.repository=<registro>/<imagen> --set image.tag=<tag>
```

`image.repository` es obligatorio. Para Spring Boot ajusta `probes.*.path` a
`/actuator/health/liveness` y `/actuator/health/readiness`.

### NetworkPolicy (Zero-Trust)

Se deniega todo el tráfico de entrada y salida salvo lo declarado:

- Entrada: solo desde el namespace del ingress controller (por defecto `ingress-nginx`) y los pods que
  indiques en `networkPolicy.ingress.fromPods`, únicamente al puerto `http`.
- Salida: DNS (kube-dns), el OpenTelemetry Collector (`observability`, puertos 4317/4318) y lo que
  añadas en `egress.cidrs` o `egress.extra`. Para llamar a las APIs de AWS declara los CIDR de tus VPC
  endpoints (puerto 443).
- Los nombres de namespace y etiquetas por defecto son supuestos habituales: ajústalos a tu clúster.

### Conectar Terraform y Helm

`terraform output -json app_environment` entrega las variables que el servicio necesita
(`SQS_QUEUE_URL`, `SNS_TOPIC_ARN`, `S3_BUCKET`, `SECRET_ID`, ...) para pasarlas en `env`. En EKS, asocia
`service_iam_policy_json` a un rol IRSA y pon su ARN en `serviceAccount.annotations`.
