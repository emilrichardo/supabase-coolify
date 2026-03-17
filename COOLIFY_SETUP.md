# Guía de Configuración en Coolify

Esta guía te lleva paso a paso para configurar Supabase en Coolify desde un repositorio privado.

## 📋 Pre-requisitos

1. **Coolify instalado y funcionando**
   - Asegúrate de tener acceso al dashboard de Coolify
   - Tu servidor debe tener los puertos 80 y 443 abiertos

2. **Dominios configurados**
   - `api.tudominio.com` → IP de tu servidor
   - `studio.tudominio.com` → IP de tu servidor
   - Configura los registros A en tu DNS

3. **Repositorio en GitHub**
   - Repositorio privado con el código de Supabase
   - GitHub App de Coolify conectada

## 🚀 Paso a Paso

### Paso 1: Preparar el Repositorio

1. **Crear el repositorio en GitHub**
   ```bash
   # En tu máquina local
   git init
   git add .
   git commit -m "Initial Supabase setup for Coolify"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
   git push -u origin main
   ```

2. **Verificar archivos necesarios**
   Asegúrate de que estos archivos estén en el repositorio:
   - `docker-compose.yml`
   - `volumes/kong/kong-template.yml`
   - `volumes/db/init/00-initial-schema.sql`
   - `.env.example` (como referencia)

### Paso 2: Configurar GitHub App en Coolify

1. Ve a tu dashboard de Coolify
2. Navega a **Settings** → **GitHub App**
3. Sigue las instrucciones para instalar la GitHub App en tu cuenta/organización
4. Asegúrate de dar permisos al repositorio privado

### Paso 3: Crear el Recurso en Coolify

1. Ve a **Resources** → **+ New**
2. Selecciona **Private Repository (with GitHub App)**
3. Selecciona tu repositorio de Supabase de la lista
4. Haz clic en **Continue**

### Paso 4: Configurar el Build Pack

1. **Build Pack**: Selecciona `Docker Compose`
2. **Docker Compose Location**: `docker-compose.yml`
3. **Base Directory**: Deja vacío (`.`) o especifica el subdirectorio si aplica
4. Haz clic en **Continue**

### Paso 5: Configurar Variables de Entorno

Este es el paso más importante. Necesitas configurar todas las variables del archivo `.env`:

#### Secrets Obligatorios

Genera estos valores en tu máquina local:

```bash
# JWT_SECRET
openssl rand -base64 32

# SECRET_KEY_BASE
openssl rand -base64 64

# LOGFLARE_API_KEY
openssl rand -hex 32

# POSTGRES_PASSWORD (password seguro)
openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
```

#### Configurar en Coolify

1. En la página de configuración del recurso, ve a la sección **Environment Variables**
2. Añade cada variable una por una:
   - `POSTGRES_PASSWORD`
   - `JWT_SECRET`
   - `ANON_KEY` (mismo valor que JWT_SECRET)
   - `SERVICE_ROLE_KEY` (mismo valor que JWT_SECRET)
   - `SECRET_KEY_BASE`
   - `LOGFLARE_API_KEY`
   - `API_EXTERNAL_URL` (ej: `https://api.tudominio.com`)
   - `SITE_URL` (ej: `https://app.tudominio.com`)
   - `KONG_HOST` (ej: `api.tudominio.com`)
   - `STUDIO_HOST` (ej: `studio.tudominio.com`)
   - `DASHBOARD_USERNAME`
   - `DASHBOARD_PASSWORD`
   - Y todas las demás variables necesarias...

> **Tip**: Puedes usar el botón "Bulk Edit" para pegar todas las variables de tu archivo `.env`

### Paso 6: Configurar Dominios

1. Ve a la pestaña **Settings** del recurso
2. En **Domains**, añade:
   ```
   https://api.tudominio.com, https://studio.tudominio.com
   ```
3. Habilita:
   - ✅ **HTTPS Enabled**
   - ✅ **Force HTTPS**
4. Guarda los cambios

### Paso 7: Configurar Auto-Deploy

1. Ve a **Advanced** → **General**
2. Habilita **Auto Deploy** para que se despliegue automáticamente en cada push
3. Guarda los cambios

### Paso 8: Primer Despliegue

1. Haz clic en el botón **Deploy**
2. Espera a que el despliegue termine (puede tardar 5-10 minutos)
3. Monitorea los logs en tiempo real

### Paso 9: Verificar el Despliegue

1. **Verificar Kong (API Gateway)**:
   ```bash
   curl https://api.tudominio.com/health
   ```

2. **Verificar Studio (Dashboard)**:
   Abre `https://studio.tudominio.com` en tu navegador

3. **Verificar API REST**:
   ```bash
   curl https://api.tudominio.com/rest/v1/ \
     -H "apikey: TU_ANON_KEY" \
     -H "Authorization: Bearer TU_ANON_KEY"
   ```

## 🔧 Configuración Post-Despliegue

### Configurar SMTP (Email)

Para que la autenticación por email funcione:

1. Ve a las variables de entorno del recurso
2. Configura las variables SMTP:
   - `SMTP_HOST`
   - `SMTP_PORT`
   - `SMTP_USER`
   - `SMTP_PASS`
   - `SMTP_ADMIN_EMAIL`
3. Redespliega

### Configurar Storage (S3)

Para almacenamiento de archivos:

1. Obtén credenciales de AWS S3 o MinIO
2. Configura las variables:
   - `STORAGE_S3_BUCKET`
   - `STORAGE_S3_ENDPOINT`
   - `STORAGE_S3_ACCESS_KEY_ID`
   - `STORAGE_S3_SECRET_ACCESS_KEY`
   - `STORAGE_S3_REGION`
3. Redespliega

### Configurar OAuth Providers

Para autenticación con Google, GitHub, etc.:

1. Crea aplicaciones OAuth en cada proveedor
2. Configura las variables correspondientes en Coolify:
   - `EXTERNAL_GOOGLE_ENABLED=true`
   - `EXTERNAL_GOOGLE_CLIENT_ID=...`
   - `EXTERNAL_GOOGLE_SECRET=...`
   - `EXTERNAL_GOOGLE_REDIRECT_URI=https://api.tudominio.com/auth/v1/callback`
3. Redespliega

## 🔄 Configurar CI/CD con GitHub Actions

### Paso 1: Obtener Credenciales de Coolify

1. Ve a **Settings** → **API Tokens** en Coolify
2. Crea un nuevo token con permisos de `deploy`
3. Copia el token

### Paso 2: Obtener Webhook URL

1. Ve a tu recurso de Supabase en Coolify
2. Ve a la pestaña **Webhooks**
3. Copia la URL del webhook de despliegue

### Paso 3: Configurar Secrets en GitHub

1. En tu repositorio de GitHub, ve a **Settings** → **Secrets and variables** → **Actions**
2. Añade los siguientes secrets:
   - `COOLIFY_TOKEN`: El token de API de Coolify
   - `COOLIFY_WEBHOOK`: La URL del webhook
   - `COOLIFY_URL`: La URL de tu instancia de Coolify (ej: `https://coolify.tudominio.com`)

### Paso 4: Probar CI/CD

1. Haz un cambio en tu repositorio local
2. Haz commit y push a la rama `main`
3. Ve a la pestaña **Actions** en GitHub
4. Verifica que el workflow se ejecute correctamente
5. Verifica en Coolify que el despliegue se haya iniciado

## 🛠️ Solución de Problemas Comunes

### Error: "No Available Server"

**Causa**: Coolify no puede encontrar un servidor disponible
**Solución**:
1. Verifica que tu servidor esté conectado a Coolify
2. Ve a **Servers** en Coolify y asegúrate de que el servidor esté "Healthy"

### Error: "Build failed"

**Causa**: Error en la construcción de la imagen
**Solución**:
1. Revisa los logs de construcción en Coolify
2. Verifica que el `docker-compose.yml` sea válido: `docker-compose config`
3. Asegúrate de que todas las variables de entorno estén configuradas

### Error: Kong no inicia

**Causa**: Problema con la configuración de Kong
**Solución**:
1. Verifica que el archivo `kong-template.yml` exista
2. Verifica que las variables `SUPABASE_ANON_KEY` y `SUPABASE_SERVICE_KEY` estén configuradas
3. Revisa los logs de Kong: `docker logs <kong-container-id>`

### Error: PostgreSQL no inicia

**Causa**: Permisos o datos corruptos
**Solución**:
1. Verifica los permisos del volumen
2. Si es la primera vez, asegúrate de que no haya datos previos
3. Revisa los logs: `docker logs <db-container-id>`

### SSL no funciona

**Causa**: DNS no configurado correctamente
**Solución**:
1. Verifica que los dominios apunten a la IP del servidor
2. Usa `dig api.tudominio.com` para verificar
3. Espera a que propague el DNS (puede tardar hasta 48 horas)

## 📊 Monitoreo

### Ver logs en Coolify

1. Ve a tu recurso
2. Haz clic en **Logs**
3. Selecciona el servicio que quieres ver (kong, db, auth, etc.)

### Ver métricas

1. Ve a **Monitoring** en el menú principal
2. Selecciona tu servidor
3. Verifica uso de CPU, memoria y disco

## 📝 Notas Importantes

### Persistencia de Datos

Los datos se almacenan en volúmenes de Docker:
- `db-data`: Base de datos PostgreSQL
- `storage-data`: Archivos de almacenamiento

**⚠️ No elimines estos volúmenes o perderás todos los datos**

### Backups

Configura backups regulares de la base de datos:

```bash
# Ejemplo de backup manual
docker exec <db-container-id> pg_dump -U supabase_admin postgres > backup.sql
```

### Actualizaciones

Para actualizar Supabase:

1. Modifica las versiones de las imágenes en `docker-compose.yml`
2. Haz commit y push
3. El CI/CD se encargará del despliegue

## 🆘 Soporte

Si encuentras problemas:

1. Revisa los logs en Coolify
2. Consulta la [documentación de Supabase](https://supabase.com/docs)
3. Consulta la [documentación de Coolify](https://coolify.io/docs)
4. Abre un issue en tu repositorio con los logs del error
