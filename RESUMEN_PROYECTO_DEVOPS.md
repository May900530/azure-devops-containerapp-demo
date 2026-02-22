# Proyecto DevOps: Contenedores en Azure con Terraform
## Resumen Completo para Entrevistas y Portfolio

---

## 1. ¿Qué es este proyecto y cuál es su propósito?

**Respuesta para entrevista:**

"Desarrollé un proyecto de DevOps end-to-end que demuestra aprovisionamiento de infraestructura como código (IaC), contenerización y despliegue continuo. El proyecto consiste en una aplicación web Node.js contenerizada y desplegada en Azure usando Terraform para la infraestructura y Azure Container Registry para gestionar las imágenes Docker."

**Propósito:**
- Demostrar conocimientos prácticos de DevOps en un entorno cloud real
- Mostrar habilidades en IaC, contenedores, CI/CD y Azure
- Crear un portfolio técnico desplegable y reproducible

---

## 2. ¿Qué tecnologías usaste y por qué?

| Tecnología | Propósito | Por qué se eligió |
|------------|-----------|-------------------|
| **Terraform** | Infrastructure as Code | Permite versionar, reutilizar y recrear infraestructura de forma declarativa y repetible |
| **Azure Container Registry (ACR)** | Registry privado de imágenes Docker | Almacena y gestiona imágenes de forma segura integrado con Azure |
| **Azure App Service (Linux Web App)** | Hosting de contenedores | Servicio PaaS gestionado que simplifica despliegue y escalado |
| **Docker** | Contenerización | Empaqueta la aplicación con todas sus dependencias para garantizar consistencia entre entornos |
| **Node.js + Express** | Aplicación web mínima | Framework ligero para demostrar el concepto sin complejidad innecesaria |
| **Azure DevOps** | Gestión de proyecto y CI/CD | Plataforma integrada para repos, pipelines y gestión de tareas |
| **Azure Cloud Shell** | Ejecución de comandos | Entorno preconfigurado con herramientas (az, terraform, git) sin setup local |

---

## 3. ¿Cuál es la arquitectura del proyecto?

### Diagrama conceptual:

```
[Código fuente] 
    ↓
[Azure Repos / GitHub]
    ↓
[Terraform] → Provisiona:
              - Resource Group
              - Azure Container Registry (ACR)
              - App Service Plan (B1 Linux)
              - Linux Web App
    ↓
[az acr build] → Construye imagen Docker y la sube al ACR
    ↓
[Web App] → Pull de imagen desde ACR → Ejecuta contenedor
    ↓
[Usuario] → Accede vía HTTPS (devopsdemo-webapp.azurewebsites.net)
```

### Componentes principales:

#### 1. Resource Group (devopsdemo-rg)
- Contenedor lógico que agrupa todos los recursos relacionados
- Facilita gestión, facturación y eliminación conjunta

#### 2. Azure Container Registry (ACR - devopsdemoacr)
- Registry privado para almacenar imágenes Docker
- Integración nativa con Azure (autenticación, red privada)
- Admin habilitado para simplificar autenticación

#### 3. App Service Plan (devopsdemo-plan)
- Define recursos de cómputo (CPU, RAM) para las apps
- SKU B1: básico pero suficiente para demo (1 core, 1.75 GB RAM)
- OS Linux (más ligero y económico para contenedores)

#### 4. Linux Web App (devopsdemo-webapp)
- Servicio PaaS que ejecuta el contenedor
- Configurado para usar imagen del ACR
- Credenciales de registry configuradas via app settings/environment

#### 5. Aplicación (container-app/)
- Node.js + Express
- Dockerfile multi-stage: FROM node:18-alpine
- Endpoint GET / que devuelve HTML con info de build

---

## 4. ¿Qué hace cada archivo del proyecto?

### Estructura del repositorio:

```
DevOps-Work-Demo/
├── container-app/
│   ├── Dockerfile          # Instrucciones para construir la imagen
│   ├── package.json        # Dependencias de Node.js (express)
│   └── server.js           # Código de la app (endpoint GET /)
├── infra/
│   └── main.tf            # Definición Terraform de infraestructura
├── .azure-pipelines.yml   # Pipeline CI/CD (preparado pero no usado por limitación Student)
└── README.md              # Documentación del proyecto
```

### Explicación de cada archivo:

#### Dockerfile
```dockerfile
FROM node:18-alpine        # imagen base ligera
WORKDIR /app
COPY package*.json ./      # copia dependencias
RUN npm install --production  # instala solo deps necesarias
COPY . .                   # copia código
ENV PORT=3000
CMD ["node","server.js"]   # comando de arranque
```

#### server.js
- Servidor Express mínimo
- Endpoint GET / que devuelve HTML
- Lee PORT del entorno (Azure lo inyecta automáticamente)
- Muestra BUILD_ID si existe (para CI/CD)

#### main.tf
- Provider azurerm (Azure Resource Manager)
- Variables (prefix, location) para reutilización
- Recursos: RG, ACR, Service Plan, Web App
- Outputs: nombres de ACR y Web App (útiles para scripts)

#### .azure-pipelines.yml
- Define pipeline con 2 stages: Build y Deploy
- Build: usa `az acr build` (construye en la nube)
- Deploy: usa `AzureWebAppContainer` task para actualizar Web App
- **Nota:** no se ejecutó por limitación de hosted agents en cuenta Student

---

## 5. ¿Cuál fue el flujo de trabajo (workflow)?

### Paso a paso:

#### 1. Diseño y planificación
- Definí la arquitectura (contenedor + ACR + Web App)
- Elegí Terraform para IaC por ser declarativo y cloud-agnostic

#### 2. Creación de la aplicación
- Desarrollé app Node.js mínima con Express
- Creé Dockerfile para contenerizar
- Probé localmente (opcional, no fue necesario)

#### 3. Infraestructura como código (Terraform)
```bash
terraform init    # descarga provider azurerm
terraform plan    # revisa cambios antes de aplicar
terraform apply   # provisiona recursos en Azure
```
- Outputs devuelven nombres de ACR y Web App

#### 4. Construcción y push de imagen
```bash
az acr build --registry devopsdemoacr --image devops-container-app:v1 --file container-app/Dockerfile container-app/
```
- Ventaja: no requiere Docker instalado localmente
- Push automático al registry

#### 5. Configuración de Web App
```bash
az webapp config container set \
  --name devopsdemo-webapp \
  --resource-group devopsdemo-rg \
  --container-image-name devopsdemoacr.azurecr.io/devops-container-app:v1 \
  --container-registry-url https://devopsdemoacr.azurecr.io \
  --container-registry-user <ACR_USER> \
  --container-registry-password <ACR_PASS>
```

#### 6. Verificación
- Accedí a URL pública: https://devopsdemo-webapp.azurewebsites.net
- Confirmé que el contenedor funciona correctamente

#### 7. Gestión de costes
```bash
terraform destroy -auto-approve
```

---

## 6. ¿Qué desafíos encontraste y cómo los resolviste?

### 1. Limitación de hosted agents en cuenta Azure Student
- **Problema:** Azure DevOps no permite usar agentes Microsoft-hosted sin pago/aprobación
- **Solución:** Ejecuté el pipeline manualmente desde Cloud Shell usando `az acr build` y `az webapp config container set`
- **Aprendizaje:** Flexibilidad para adaptar workflows según limitaciones del entorno

### 2. Sintaxis de Terraform (provider v4.x)
- **Problema:** Errores de sintaxis con bloques en una línea
- **Solución:** Reformateé a bloques multilínea estándar
- **Aprendizaje:** Importancia de respetar convenciones y leer documentación oficial

### 3. Configuración de credenciales ACR
- **Problema:** App settings mostraban "null" para DOCKER_REGISTRY_SERVER_PASSWORD
- **Solución:** Usé `az webapp config container set` (método correcto) en lugar de app settings manuales
- **Aprendizaje:** Diferenciar entre configuración de app y configuración de container runtime

### 4. Capacidad de región (westeurope)
- **Problema:** No había instancias disponibles para App Service Plan B1 en westeurope
- **Solución:** Cambié región a northeurope en Terraform y volví a aplicar
- **Aprendizaje:** Planificar redundancia de región en arquitecturas reales

---

## 7. ¿Qué habilidades técnicas demuestra este proyecto?

- ✅ **Infrastructure as Code (IaC):** Terraform para definir y provisionar infraestructura
- ✅ **Contenerización:** Dockerfile, gestión de imágenes, buenas prácticas
- ✅ **Cloud computing (Azure):** ACR, App Service, Resource Groups, CLI
- ✅ **CI/CD (conceptual):** Pipeline YAML preparado, az acr build
- ✅ **Gestión de secretos:** Credenciales ACR, variables de entorno
- ✅ **Control de versiones:** Git, Azure Repos
- ✅ **Troubleshooting:** Resolución de errores de config, logs, provider versions
- ✅ **Gestión de costes:** Conocimiento de pricing, destrucción de recursos
- ✅ **Documentación:** README, comentarios, evidencias

---

## 8. ¿Cómo mejorarías este proyecto en un entorno real?

### Mejoras recomendadas:

#### 1. CI/CD completo
- Usar self-hosted agent o GitHub Actions
- Integrar tests automatizados (unit, integration)
- Implementar stages (dev, staging, prod) con approvals

#### 2. Seguridad
- Usar Azure Key Vault para secretos
- Managed Identity en lugar de admin credentials
- Escaneo de vulnerabilidades de imágenes (Trivy, Azure Defender)
- HTTPS only, custom domain con certificado

#### 3. Monitoreo y observabilidad
- Application Insights para telemetría
- Log Analytics para logs centralizados
- Alerts para errores o downtime

#### 4. Escalabilidad
- Auto-scaling del Service Plan según carga
- Load balancer / Traffic Manager para multi-región
- ACR geo-replication

#### 5. Infraestructura
- Backend remoto para Terraform state (Azure Storage + state locking)
- Módulos Terraform reutilizables
- Terraform workspaces para múltiples entornos

#### 6. Networking
- VNet integration para comunicación privada
- Private endpoint para ACR
- WAF (Web Application Firewall) para protección

---

## 9. Pregunta típica de entrevista: Explica el flujo completo de un cambio en el código

**Respuesta ideal:**

"Si hago un cambio en `server.js`:

1. **Commit y push** al repo (Azure Repos/GitHub)
2. **Se dispara el pipeline** automáticamente (trigger: main branch)
3. **Stage Build:**
   - Pipeline ejecuta `az acr build` que:
     - Lee el Dockerfile
     - Construye la imagen en la nube
     - Tagea con Build.BuildId (ej. :v42)
     - Push automático al ACR
4. **Stage Deploy:**
   - Pipeline ejecuta task `AzureWebAppContainer`
   - Actualiza la Web App con la nueva imagen (ACR.azurecr.io/app:v42)
   - Azure hace pull de la imagen y reinicia el contenedor
5. La **nueva versión queda disponible** en https://devopsdemo-webapp.azurewebsites.net
6. (Opcional) Monitoreo en Application Insights confirma salud de la app"

---

## 10. Comandos útiles para reproducir el proyecto

### Preparación
```bash
# Login Azure
az login
az account set --subscription "<SUBSCRIPTION_ID>"

# Clonar repo
git clone https://dev.azure.com/<ORG>/<PROYECTO>/_git/<REPO>
cd <REPO>
```

### Provisionar infraestructura
```bash
cd infra
terraform init
terraform plan
terraform apply -auto-approve
# Anotar outputs: acr_name, web_app_name
```

### Construir y desplegar
```bash
# Construir imagen
az acr build --registry <ACR_NAME> --image devops-container-app:v1 --file container-app/Dockerfile container-app/

# Configurar Web App
ACR_USER=$(az acr credential show --name <ACR_NAME> --query "username" -o tsv)
ACR_PASS=$(az acr credential show --name <ACR_NAME> --query "passwords[0].value" -o tsv)

az webapp config container set \
  --name <WEBAPP_NAME> \
  --resource-group <RG_NAME> \
  --container-image-name <ACR_NAME>.azurecr.io/devops-container-app:v1 \
  --container-registry-url https://<ACR_NAME>.azurecr.io \
  --container-registry-user $ACR_USER \
  --container-registry-password $ACR_PASS

# Reiniciar
az webapp restart --name <WEBAPP_NAME> --resource-group <RG_NAME>
```

### Verificar
```bash
# Obtener URL
az webapp show --name <WEBAPP_NAME> --resource-group <RG_NAME> --query "defaultHostName" -o tsv
# Abrir en navegador
```

### Limpieza
```bash
cd infra
terraform destroy -auto-approve
```

---

## 11. Costes estimados (Azure)

| Recurso | SKU | Coste aproximado |
|---------|-----|------------------|
| App Service Plan | B1 (1 core, 1.75GB RAM) | ~13 USD/mes |
| Container Registry | Basic | ~5 USD/mes |
| **Total** | | **~18 USD/mes** |

**Nota:** Costes prorrateados por horas. Destruir recursos al terminar evita cargos.

---

## 12. Elevator pitch (30 segundos)

"Construí una aplicación web contenerizada desplegada en Azure usando Terraform para la infraestructura. La app Node.js se empaqueta en Docker, se almacena en Azure Container Registry y se despliega automáticamente en App Service. Todo el código está versionado y documentado, demostrando IaC, CI/CD y buenas prácticas de DevOps."

---

## 13. Ejemplo de post para LinkedIn

> 🚀 Completé un proyecto de DevOps end-to-end usando Azure, Terraform y Docker. Implementé IaC para aprovisionar infraestructura, contenerización de una app Node.js y despliegue automatizado en Azure Container Registry + App Service.
> 
> **Tecnologías:** Terraform, Azure (ACR, Web App, Cloud Shell), Docker, Node.js, Azure DevOps.
> 
> **Repo:** [link a GitHub]
> 
> #Azure #DevOps #Terraform #Docker #CloudComputing #IaC

---

## 14. Preguntas adicionales de entrevista y respuestas

### ¿Por qué elegiste Terraform en lugar de ARM templates o Bicep?
- Terraform es cloud-agnostic (reutilizable en AWS, GCP)
- Sintaxis HCL más legible que JSON de ARM
- Ecosistema de providers y módulos muy amplio
- State management facilita detección de drift

### ¿Qué ventajas tiene contenerizar la aplicación?
- Consistencia entre entornos (dev, staging, prod)
- Aislamiento de dependencias
- Portabilidad entre clouds
- Escalado horizontal más sencillo
- Versionado de imágenes

### ¿Cómo gestionarías secretos en producción?
- Azure Key Vault para almacenamiento seguro
- Managed Identity para acceso sin credenciales hardcoded
- App Configuration para settings no sensibles
- Terraform data sources para inyectar secrets en runtime

### ¿Qué harías si la aplicación no arranca?
1. Ver logs: `az webapp log tail --name <APP> --resource-group <RG>`
2. Revisar Application Insights (errores, excepciones)
3. Verificar imagen en ACR: `az acr repository show-tags --name <ACR> --repository <IMAGE>`
4. Comprobar configuración: variables de entorno, credenciales ACR
5. Probar imagen localmente: `docker run -p 3000:3000 <IMAGE>`

### ¿Cómo implementarías blue-green deployment?
- Usar deployment slots en App Service
- Pipeline despliega en slot "staging"
- Tests automatizados validan staging
- Swap automático o manual hacia producción
- Rollback instantáneo si falla

---

## 15. Recursos adicionales

- [Documentación Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Container Registry docs](https://learn.microsoft.com/azure/container-registry/)
- [Azure App Service containers](https://learn.microsoft.com/azure/app-service/configure-custom-container)
- [Best practices Dockerfile](https://docs.docker.com/develop/dev-best-practices/)

---

**Proyecto desarrollado por:** Maisbeiby Ramon  
**Fecha:** Febrero 2026  
**Contacto:** [LinkedIn] | [GitHub]  
**Organización Azure DevOps:** my-azure-devops-project-4  
**Proyecto:** DevOps-Work-Demo
