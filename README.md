# Supabase en Coolify v4

Configuración completa para desplegar **Supabase** en **Coolify v4.0.0-beta.462+** usando Docker Compose.

## ✨ Características

- ✅ **PostgreSQL 15** con extensiones de Supabase
- ✅ **GoTrue** (Auth) con OAuth, MFA, SAML
- ✅ **PostgREST** para API REST automática
- ✅ **Realtime** para WebSockets
- ✅ **Storage** con soporte S3
- ✅ **Edge Functions** con Deno
- ✅ **Supabase Studio** (Dashboard)
- ✅ **Kong** como API Gateway
- ✅ **Analytics** con Logflare
- ✅ SSL automático con Let's Encrypt
- ✅ Auto-deploy desde GitHub
- ✅ Optimizado para Coolify v4

## 📋 Requisitos

- **Coolify v4.0.0-beta.400+**
- Servidor con **4GB RAM mínimo** (recomendado: 8GB)
- **2 CPU** mínimo (recomendado: 4)
- Dominios configurados en DNS
- Repositorio privado en GitHub

## 🚀 Despliegue Rápido

### 1. Clonar y Configurar

```bash
# Clonar el repositorio
git clone <tu-repositorio-privado>
cd supabase-coolify

# Generar secrets automáticamente
./scripts/generate-secrets.sh

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus dominios y secrets
```

### 2. Subir a GitHub

```bash
git add .
git commit -m "Initial Supabase setup"
git push origin main
```

### 3. Desplegar en Coolify v4

1. Ve a tu dashboard de Coolify v4
2. **Projects** → **+ New Resource**
3. Selecciona **Private Repository (with GitHub App)**
4. Selecciona tu repositorio
5. **Build Pack**: `Docker Compose`
6. Configura las variables de entorno (copia desde `.env`)
7. Configura los dominios:
   - `https://api.tudominio.com`
   - `https://studio.tudominio.com`
8. **Deploy**

## 📁 Estructura del Proyecto

```
supabase-coolify/
├── docker-compose.yml          # Configuración principal
├── .env.example                # Plantilla de variables
├── coolify.json                # Configuración específica de Coolify v4
├── README.md                   # Este archivo
├── COOLIFY_V4_SETUP.md        # Guía detallada de Coolify v4
├── scripts/
│   ├── generate-secrets.sh    # Generar secrets seguros
│   └── setup-local.sh         # Configuración local
├── volumes/
│   ├── kong/kong-template.yml # Configuración de Kong
│   ├── db/init/               # Scripts de inicialización
│   └── functions/             # Edge Functions
└── .github/workflows/
    └── deploy.yml             # CI/CD para GitHub Actions
```

## 🔐 Variables de Entorno Obligatorias

| Variable | Descripción |
|----------|-------------|
| `POSTGRES_PASSWORD` | Contraseña de PostgreSQL |
| `JWT_SECRET` | Secret para JWT tokens |
| `ANON_KEY` | API key pública (mismo valor que JWT_SECRET) |
| `SERVICE_ROLE_KEY` | API key de servicio (mismo valor que JWT_SECRET) |
| `SECRET_KEY_BASE` | Secret para Realtime |
| `LOGFLARE_API_KEY` | API key para Logflare |
| `KONG_HOST` | Dominio para API Gateway |
| `STUDIO_HOST` | Dominio para Dashboard |
| `API_EXTERNAL_URL` | URL externa de la API |
| `SITE_URL` | URL principal del sitio |

## 🌐 Servicios y URLs

| Servicio | URL | Descripción |
|----------|-----|-------------|
| Supabase Studio | `https://studio.tudominio.com` | Dashboard administrativo |
| API REST | `https://api.tudominio.com/rest/v1/` | API REST de PostgreSQL |
| Auth | `https://api.tudominio.com/auth/v1/` | API de Autenticación |
| Storage | `https://api.tudominio.com/storage/v1/` | API de Almacenamiento |
| Realtime | `https://api.tudominio.com/realtime/v1/` | WebSockets |

## 🔄 CI/CD

El proyecto incluye un workflow de GitHub Actions para despliegue automático.

### Configurar Secrets en GitHub

Ve a **Settings** → **Secrets and variables** → **Actions**:

| Secret | Descripción |
|--------|-------------|
| `COOLIFY_TOKEN` | API token de Coolify (Settings → API Tokens) |
| `COOLIFY_WEBHOOK` | Webhook URL del recurso |
| `COOLIFY_URL` | URL de tu instancia de Coolify |

## 🛠️ Scripts Útiles

### Generar Secrets

```bash
./scripts/generate-secrets.sh
```

### Configuración Local (Desarrollo)

```bash
./scripts/setup-local.sh
docker-compose up -d
```

## 📚 Documentación

- **[COOLIFY_V4_SETUP.md](COOLIFY_V4_SETUP.md)** - Guía completa de configuración en Coolify v4
- **[.env.example](.env.example)** - Todas las variables disponibles
- [Documentación de Supabase](https://supabase.com/docs)
- [Documentación de Coolify](https://coolify.io/docs)

## 🛡️ Seguridad

- **Nunca** subas el archivo `.env` a GitHub
- Usa contraseñas seguras (mínimo 32 caracteres)
- Habilita 2FA en tu cuenta de Coolify
- Configura firewalls y reglas de seguridad en tu servidor
- Realiza backups regulares de la base de datos

## 🐛 Solución de Problemas

### Kong no inicia

Verifica que las variables `ANON_KEY` y `SERVICE_ROLE_KEY` estén configuradas correctamente.

### PostgreSQL no inicia

Verifica los permisos del volumen y que no haya datos previos corruptos.

### SSL no funciona

Asegúrate de que los dominios apunten correctamente a la IP del servidor.

Para más soluciones, consulta [COOLIFY_V4_SETUP.md](COOLIFY_V4_SETUP.md).

## 📝 Notas para Coolify v4

- Coolify v4 maneja automáticamente las redes Docker
- Los labels con `$` se escapan automáticamente
- Las variables `SERVICE_FQDN_*` se generan automáticamente
- Los health checks están configurados en los labels

## 📄 Licencia

MIT

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor, abre un issue o pull request.

## 💬 Soporte

- [Discord de Coolify](https://discord.gg/coolify)
- [GitHub Issues de Coolify](https://github.com/coollabsio/coolify/issues)
- [Documentación de Supabase](https://supabase.com/docs)
# supabase-coolify
