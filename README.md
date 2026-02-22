# Proyecto DevOps: Aplicación en Contenedor Docker desplegada en Azure con Terraform

![Azure](https://img.shields.io/badge/Azure-0089D6?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-623CE4?style=for-the-badge&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)

## Descripción

Implementé un proyecto DevOps end-to-end que demuestra habilidades en Infrastructure as Code (IaC), contenedorización y despliegue en la nube. El proyecto consiste en una aplicación web Node.js empaquetada en contenedor Docker, desplegada en Azure Web App utilizando Terraform para provisionar toda la infraestructura y Azure Container Registry para gestionar las imágenes Docker.

### Objetivos del proyecto

- Demostrar conocimientos prácticos de DevOps en un entorno cloud real
- Implementar Infrastructure as Code con Terraform
- Aplicar mejores prácticas de contenedorización con Docker
- Gestionar despliegue de contenedores en Azure
- Resolver desafíos técnicos reales de forma operativa

---

## Stack Técnico

| Tecnología | Propósito | Por qué se eligió |
|------------|-----------|-------------------|
| **Terraform** | Infrastructure as Code | Permite versionar y reproducir infraestructura de forma declarativa |
| **Azure Container Registry (ACR)** | Registry privado de imágenes Docker | Almacenamiento seguro e integración nativa con Azure |
| **Azure App Service** | Hosting de contenedores | PaaS gestionado que simplifica despliegue y escalado |
| **Docker** | Contenerización | Garantiza consistencia entre entornos |
| **Node.js + Express** | Aplicación web | Framework ligero para demostrar el concepto |
| **Azure DevOps** | Gestión de proyecto y CI/CD | Plataforma integrada para repos y pipelines |
| **Azure Cloud Shell** | Ejecución de comandos | Entorno preconfigurado con todas las herramientas |

---

## Arquitectura

```
┌─────────────────┐
│  Código fuente  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Azure Repos    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────────┐
│   Terraform     │─────▶│  Resource Group      │
│                 │      │  - devopsdemo-rg     │
└─────────────────┘      └──────────────────────┘
         │
         ├──────────────▶ Azure Container Registry
         │                (devopsdemoacr)
         │
         ├──────────────▶ App Service Plan
         │                (devopsdemo-plan, B1)
         │
         └──────────────▶ Linux Web App
                          (devopsdemo-webapp)
         
         ▼
┌─────────────────┐
│  az acr build   │──────▶ Construye y sube imagen al ACR
└─────────────────┘
         │
         ▼
┌─────────────────┐
│   Web App       │──────▶ Pull de imagen desde ACR
└─────────────────┘
         │
         ▼
┌─────────────────┐
│   Usuario       │──────▶ Acceso HTTPS
└─────────────────┘        devopsdemo-webapp.azurewebsites.net
```

### Componentes desplegados

- **Resource Group** (`devopsdemo-rg`): Contenedor lógico para todos los recursos
- **Azure Container Registry** (`devopsdemoacr`): Registry privado para imágenes Docker
- **App Service Plan** (`devopsdemo-plan`): SKU B1 (1 core, 1.75 GB RAM, Linux)
- **Linux Web App** (`devopsdemo-webapp`): Ejecuta el contenedor Docker

---

## Configuración Inicial

### Creación de Organización en Azure DevOps

Para poder trabajar con Azure DevOps, primero creé una organización y un proyecto:

1. **Organización creada:** `my-azure-devops-project-4`
2. **Proyecto creado:** `DevOps-Work-Demo`
3. **Repositorio:** Azure Repos (Git)
4. **Service Connection:** Configuré una conexión de servicio con Azure usando Service Principal para permitir despliegues automatizados

### Service Principal

Creé un Service Principal en Azure AD para autenticar Azure DevOps con mi suscripción de Azure:

```bash
az ad sp create-for-rbac --name "AzureDevOps-SP" --role contributor --scopes /subscriptions/<SUBSCRIPTION_ID>
```

Este Service Principal se utilizó para:
- Configurar la Service Connection en Azure DevOps
- Permitir que Terraform gestione recursos en Azure
- Ejecutar comandos Azure CLI desde Cloud Shell

---

## Flujo de Trabajo

### 1. Provisionar infraestructura

```bash
cd infra
terraform init
terraform plan
terraform apply -auto-approve
```

### 2. Construir y subir imagen a ACR

```bash
az acr build \
  --registry devopsdemoacr \
  --image devops-container-app:v1 \
  --file container-app/Dockerfile \
  container-app/
```

### 3. Configurar Web App para usar la imagen

```powershell
$ACR_USER = az acr credential show --name devopsdemoacr --query "username" -o tsv
$ACR_PASS = az acr credential show --name devopsdemoacr --query "passwords[0].value" -o tsv

az webapp config container set `
  --name devopsdemo-webapp `
  --resource-group devopsdemo-rg `
  --container-image-name devopsdemoacr.azurecr.io/devops-container-app:v1 `
  --container-registry-url https://devopsdemoacr.azurecr.io `
  --container-registry-user $ACR_USER `
  --container-registry-password $ACR_PASS
```

### 4. Reiniciar y verificar

```bash
az webapp restart --name devopsdemo-webapp --resource-group devopsdemo-rg

# Verificar URL
az webapp show --name devopsdemo-webapp --resource-group devopsdemo-rg --query "defaultHostName" -o tsv
```

### 5. Limpieza (recursos eliminados para evitar costes)

```bash
cd infra
terraform destroy -auto-approve
```

**Estado actual:** Todos los recursos fueron eliminados para no generar costes.

---

## Desafíos Encontrados y Soluciones

### 1. Limitación de hosted agents en Azure DevOps

**Problema:** La organización no tenía hosted parallelism (agentes Microsoft-hosted bloqueados en cuentas Student).

**Solución:** Implementé un workaround operativo:
- Usé `az acr build` para construir y pushear la imagen directamente al ACR (sin pipeline)
- Configuré manualmente la Web App con `az webapp config container set`
- Mantuve el YAML del pipeline en el repo para uso futuro con self-hosted agent

### 2. Errores de sintaxis en Terraform (azurerm provider v4.x)

**Problema:** Bloques de configuración en una sola línea no permitidos en provider v4.x.

**Solución:** 
- Reformateé todos los bloques a formato multi-línea
- Migré de `azurerm_app_service_plan` (deprecado) a `azurerm_service_plan`
- Actualicé `site_config` para usar `application_stack` correctamente

### 3. Capacidad agotada en región westeurope

**Problema:** Error 409 Conflict al crear App Service Plan en westeurope.

**Solución:** Cambié la variable `location` de "westeurope" a "northeurope" y reaplicé Terraform.

### 4. Credenciales del ACR mostrando "null"

**Problema:** Las credenciales del registry no aparecían en la configuración del Web App.

**Solución:** 
- Confirmé que es un comportamiento esperado (security masking)
- Verifiqué que la aplicación se desplegó correctamente a pesar del display "null"
- Usé `az webapp config container set` en lugar de app settings genéricos

---

## Estructura del Proyecto

```
DevOps-Work-Demo/
├── container-app/
│   ├── Dockerfile          # Instrucciones para construir la imagen
│   ├── package.json        # Dependencias de Node.js
│   └── server.js           # Código de la aplicación
├── infra/
│   └── main.tf            # Definición Terraform (RG, ACR, Plan, Web App)
├── .azure-pipelines.yml   # Pipeline CI/CD (preparado pero no ejecutado)
├── README.md              # Este archivo
└── RESUMEN_PROYECTO_DEVOPS.md  # Documentación completa
```

---

## Aprendizajes Clave

- **Infrastructure as Code:** Terraform permite reproducir infraestructura completa en minutos
- **Azure Container Registry:** `az acr build` construye en la nube sin necesidad de Docker local
- **App Service for Containers:** Configuración correcta de registry credentials es crítica
- **Workarounds operativos:** Ante limitaciones de plataforma, soluciones manuales bien documentadas son válidas
- **Cost management:** `terraform destroy` es esencial para evitar cargos inesperados
- **Provider versions matter:** Cambios breaking entre versiones requieren atención a documentación

---

## Costes

| Recurso | SKU | Coste aproximado |
|---------|-----|------------------|
| App Service Plan | B1 (1 core, 1.75GB RAM) | ~13 USD/mes |
| Container Registry | Basic | ~5 USD/mes |
| **Total** | | **~18 USD/mes** |

**Nota:** Los recursos fueron destruidos para no generar costes. En producción, costes prorrateados por horas.

---

## Screenshots

La aplicación fue desplegada exitosamente en: `https://devopsdemo-webapp.azurewebsites.net`

(Mostraba: "DevOps Container App - Build: local")

---

## Mejoras Futuras

- [ ] Implementar self-hosted agent para ejecutar pipeline completo
- [ ] Añadir Azure Key Vault para gestión de secretos
- [ ] Configurar Application Insights para monitoreo
- [ ] Implementar deployment slots (blue-green deployment)
- [ ] Añadir autoscaling rules
- [ ] Configurar custom domain y certificado SSL
- [ ] Integrar ARM/Bicep para comparación con Terraform
- [ ] Añadir tests automatizados en pipeline

---

## Recursos Adicionales

- [Documentación Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Container Registry docs](https://learn.microsoft.com/azure/container-registry/)
- [Azure App Service containers](https://learn.microsoft.com/azure/app-service/configure-custom-container)
- [Best practices Dockerfile](https://docs.docker.com/develop/dev-best-practices/)

---

## Autor

**Maisbeiby Ramon**

LinkedIn: https://www.linkedin.com/in/maisbeibyramon  
GitHub: https://github.com/May900530  
Correo electrónico: may900530@gmail.com

---

## Licencia

Este proyecto está bajo licencia MIT - ver archivo LICENSE para más detalles.

---

## Agradecimientos

Proyecto desarrollado como parte de mi portfolio para demostrar habilidades en DevOps, Cloud Engineering e Infrastructure as Code.

Si este proyecto te resultó útil, ¡dale una estrella!
