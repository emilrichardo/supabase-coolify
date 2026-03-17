# Guía de Configuración en Coolify v4.0.0-beta.462

Esta guía está específicamente actualizada para **Coolify v4.0.0-beta.462**.

## ⚠️ Cambios Importantes en Coolify v4

- **Nuevo sistema de redes**: Coolify v4 maneja automáticamente las redes Docker
- **Variables mágicas**: Nuevas variables como `SERVICE_FQDN_*` para URLs automáticas
- **Health checks mejorados**: Soporte nativo para health checks en labels
- **Escape de `$`**: Por defecto, los labels con `$` se escapan automáticamente
- **Mejor manejo de volúmenes**: Persistencia mejorada de datos

## 📋 Pre-requisitos

1. **Coolify v4.0.0-beta.400+** instalado
2. **Servidor** con mínimo 4GB RAM, 2 CPU
3. **Dominios** configurados en DNS apuntando al servidor
4. **GitHub App** conectada en Coolify

## 🚀 Pasos de Instalación

### Paso 1: Preparar el Repositorio

```bash
# Clonar o crear el repositorio
git clone <tu-repositorio> supabase-coolify
cd supabase-coolify

# Generar secrets
./scripts/generate-secrets.sh

# Copiar y configurar variables de entorno
cp .env.example .env
# Editar .env con tus valores
```

### Paso 2: Configurar Variables de Entorno

Edita el archivo `.env` con tus valores:

```env
# Secrets (generados automáticamente o manualmente)
POSTGRES_PASSWORD=tu-password-segura
JWT_SECRET=tu-jwt-secret
ANON_KEY=mismo-valor-que-jwt
SERVICE_ROLE_KEY=mismo-valor-que-jwt
SECRET_KEY_BASE=tu-secret-key-base
LOGFLARE_API_KEY=tu-logflare-key

# Dominios (IMPORTANTE: deben coincidir con tu DNS)
KONG_HOST=api.tudominio.com
STUDIO_HOST=studio.tudominio.com
API_EXTERNAL_URL=https://api.tudominio.com
SITE_URL=https://studio.tudominio.com

# Credenciales del Dashboard
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=tu-password-segura
```

### Paso 3: Crear Recurso en Coolify v4

1. **Iniciar sesión** en tu dashboard de Coolify v4
2. Ir a **Proyectos** → Seleccionar o crear un proyecto
3. Click en **+ New Resource**
4. Seleccionar **Private Repository (with GitHub App)**
5. Seleccionar tu repositorio de Supabase

### Paso 4: Configurar Build Pack

1. **Build Pack**: Seleccionar `Docker Compose`
2. **Docker Compose Location**: `docker-compose.yml`
3. **Base Directory**: `.` (directorio raíz)
4. Click en **Continue**

### Paso 5: Configurar Variables de Entorno en Coolify

En la sección **Environment Variables**:

#### Opción A: Importar desde archivo (Recomendado)

1. Click en **Bulk Edit** (o "Editor masivo")
2. Copiar y pegar todo el contenido de tu archivo `.env`
3. Click en **Save**

#### Opción B: Configurar manualmente

Añadir las variables obligatorias:

| Variable | Valor de ejemplo | Descripción |
|----------|-----------------|-------------|
| `POSTGRES_PASSWORD` | `super-secret-pass` | Password de PostgreSQL |
| `JWT_SECRET` | `base64-encoded...` | Secret para JWT |
| `ANON_KEY` | `base64-encoded...` | API key pública |
| `SERVICE_ROLE_KEY` | `base64-encoded...` | API key de servicio |
| `SECRET_KEY_BASE` | `base64-encoded...` | Secret para Realtime |
| `LOGFLARE_API_KEY` | `hex-string...` | API key de Logflare |
| `KONG_HOST` | `api.tudominio.com` | Dominio para API |
| `STUDIO_HOST` | `studio.tudominio.com` | Dominio para Dashboard |
| `API_EXTERNAL_URL` | `https://api.tudominio.com` | URL externa API |
| `SITE_URL` | `https://studio.tudominio.com` | URL del sitio |

### Paso 6: Configurar Dominios

1. Ir a la pestaña **Settings**
2. En **Domains**, añadir:
   ```
   https://api.tudominio.com, https://studio.tudominio.com
   ```
3. Habilitar:
   - ✅ **HTTPS Enabled**
   - ✅ **Force HTTPS**
4. **Save**

### Paso 7: Configurar Auto-Deploy

1. Ir a **Advanced** → **General**
2. Habilitar **Auto Deploy**
3. Seleccionar la rama: `main` (o tu rama principal)
4. **Save**

### Paso 8: Desplegar

1. Click en **Deploy**
2. Esperar a que termine el despliegue (5-10 minutos)
3. Monitorear los logs en tiempo real

## 🔧 Configuración Post-Despliegue

### Verificar Servicios

Una vez desplegado, verifica que todos los servicios estén funcionando:

```bash
# Verificar Kong (API Gateway)
curl https://api.tudominio.com/health

# Verificar Studio (Dashboard)
curl https://studio.tudominio.com/api/health
```

### Configurar SMTP (Email)

Para habilitar el envío de emails:

1. Ir a **Environment Variables**
2. Añadir:
   ```
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=tu-email@gmail.com
   SMTP_PASS=tu-app-password
   SMTP_ADMIN_EMAIL=admin@tudominio.com
   ENABLE_EMAIL_AUTOCONFIRM=false
   ```
3. **Redeploy**

### Configurar Storage (S3)

Para almacenamiento de archivos:

1. Añadir variables:
   ```
   STORAGE_S3_BUCKET=tu-bucket
   STORAGE_S3_ENDPOINT=https://s3.amazonaws.com
   STORAGE_S3_ACCESS_KEY_ID=tu-access-key
   STORAGE_S3_SECRET_ACCESS_KEY=tu-secret-key
   STORAGE_S3_REGION=us-east-1
   ```
2. **Redeploy**

## 🔄 CI/CD con GitHub Actions

### Configurar Secrets en GitHub

1. Ir a tu repositorio en GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Añadir:

| Secret | Descripción | Cómo obtener |
|--------|-------------|--------------|
| `COOLIFY_TOKEN` | Token de API | Coolify → Settings → API Tokens |
| `COOLIFY_WEBHOOK` | Webhook URL | Coolify → Resource → Webhooks |
| `COOLIFY_URL` | URL de Coolify | `https://coolify.tudominio.com` |

### Probar CI/CD

1. Hacer un cambio en el código
2. Commit y push a `main`
3. Verificar en GitHub Actions que el workflow se ejecute
4. Verificar en Coolify que el despliegue se inicie automáticamente

## 🛠️ Solución de Problemas

### Error: "No Available Server"

**Causa**: El servidor no está disponible o no tiene recursos suficientes

**Solución**:
1. Verificar en **Servers** que el servidor esté "Healthy"
2. Verificar que haya suficiente RAM y disco disponible
3. Reiniciar el servidor si es necesario

### Error: "Build failed"

**Causa**: Error en la construcción de Docker

**Solución**:
1. Revisar logs de construcción en Coolify
2. Verificar que el `docker-compose.yml` sea válido:
   ```bash
   docker-compose config
   ```
3. Asegurar que todas las variables de entorno estén configuradas

### Kong no inicia

**Causa**: Problema con la configuración

**Solución**:
1. Verificar logs: `docker logs <kong-container-id>`
2. Asegurar que `kong-template.yml` existe
3. Verificar que las variables `ANON_KEY` y `SERVICE_ROLE_KEY` estén definidas

### PostgreSQL no inicia

**Causa**: Permisos o datos corruptos

**Solución**:
1. Verificar logs: `docker logs <db-container-id>`
2. Si es primera vez, asegurar que no hay datos previos
3. Verificar permisos del volumen

### SSL no funciona

**Causa**: DNS no configurado correctamente

**Solución**:
1. Verificar DNS:
   ```bash
   dig api.tudominio.com
   dig studio.tudominio.com
   ```
2. Asegurar que apunten a la IP del servidor
3. Esperar propagación DNS (hasta 48 horas)

## 📊 Monitoreo en Coolify v4

### Ver Logs

1. Ir al recurso de Supabase
2. Click en **Logs**
3. Seleccionar el servicio (kong, db, auth, etc.)

### Métricas

1. Ir a **Monitoring**
2. Seleccionar el servidor
3. Ver CPU, memoria, disco y red

### Health Checks

Coolify v4 muestra el estado de salud de cada servicio:
- 🟢 **Healthy**: Funcionando correctamente
- 🟡 **Starting**: Iniciando
- 🔴 **Unhealthy**: Problemas detectados

## 📝 Notas Específicas de Coolify v4

### Escape de Caracteres `$`

En Coolify v4, los labels con `$` se escapan automáticamente. Si necesitas desactivar esto:

1. Ir a **Advanced** → **Docker**
2. Deshabilitar **Escape Dollar Signs in Labels**

### Redes Docker

Coolify v4 crea automáticamente una red para cada recurso. No necesitas configurar redes manualmente.

### Volúmenes Persistentes

Los volúmenes definidos en `docker-compose.yml` se persisten automáticamente:
- `db-data`: Datos de PostgreSQL
- `storage-data`: Archivos de almacenamiento

**⚠️ No elimines estos volúmenes o perderás todos los datos**

### Variables Mágicas

Coolify v4 genera automáticamente algunas variables:
- `SERVICE_FQDN_*`: URLs completas para servicios
- `SERVICE_PASSWORD_*`: Contraseñas generadas
- `COOLIFY_CONTAINER_NAME`: Nombre del contenedor

## 🆘 Soporte

Si encuentras problemas:

1. Revisar logs en Coolify
2. Consultar [documentación de Coolify](https://coolify.io/docs)
3. Consultar [documentación de Supabase](https://supabase.com/docs)
4. [Discord de Coolify](https://discord.gg/coolify)
5. [GitHub Issues de Coolify](https://github.com/coollabsio/coolify/issues)

## 📚 Recursos Adicionales

- [Coolify v4 Docs](https://coolify.io/docs)
- [Supabase Self-Hosting](https://supabase.com/docs/guides/self-hosting/docker)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
