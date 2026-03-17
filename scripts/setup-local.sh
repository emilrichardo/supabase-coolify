#!/bin/bash

# Script de configuración local para desarrollo
# Uso: ./scripts/setup-local.sh

set -e

echo "🚀 Configurando Supabase para desarrollo local..."
echo ""

# Verificar que Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado. Por favor instala Docker primero."
    exit 1
fi

# Verificar que Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose no está instalado. Por favor instálalo primero."
    exit 1
fi

# Crear archivo .env si no existe
if [ ! -f .env ]; then
    echo "📄 Creando archivo .env desde .env.example..."
    cp .env.example .env
    
    # Generar secrets automáticamente
    echo "🔐 Generando secrets..."
    
    JWT_SECRET=$(openssl rand -base64 32)
    SECRET_KEY_BASE=$(openssl rand -base64 64)
    LOGFLARE_API_KEY=$(openssl rand -hex 32)
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    DASHBOARD_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    
    # Reemplar valores en .env
    sed -i.bak "s/your-super-secret-postgres-password-here/$POSTGRES_PASSWORD/g" .env
    sed -i.bak "s/your-super-secret-jwt-token-with-at-least-32-characters-long/$JWT_SECRET/g" .env
    sed -i.bak "s/your-anon-key-here/$JWT_SECRET/g" .env
    sed -i.bak "s/your-service-role-key-here/$JWT_SECRET/g" .env
    sed -i.bak "s/your-super-secret-secret-key-base-with-at-least-64-characters-long/$SECRET_KEY_BASE/g" .env
    sed -i.bak "s/your-logflare-api-key-here/$LOGFLARE_API_KEY/g" .env
    sed -i.bak "s/your-secure-dashboard-password/$DASHBOARD_PASSWORD/g" .env
    
    # Configurar URLs locales
    sed -i.bak "s|https://api.tudominio.com|http://localhost:8000|g" .env
    sed -i.bak "s|https://app.tudominio.com|http://localhost:3000|g" .env
    sed -i.bak "s|api.tudominio.com|localhost|g" .env
    sed -i.bak "s|studio.tudominio.com|localhost|g" .env
    
    rm -f .env.bak
    
    echo "✅ Archivo .env creado con secrets generados automáticamente"
    echo ""
    echo "🔑 Credenciales del Dashboard:"
    echo "   Usuario: supabase"
    echo "   Contraseña: $DASHBOARD_PASSWORD"
    echo ""
else
    echo "📄 El archivo .env ya existe. Usando configuración existente."
fi

# Crear directorios necesarios
mkdir -p volumes/db/data
mkdir -p volumes/storage/data
mkdir -p volumes/functions

echo "📁 Directorios creados"
echo ""

# Verificar que los archivos de configuración existen
if [ ! -f docker-compose.yml ]; then
    echo "❌ No se encontró docker-compose.yml"
    exit 1
fi

if [ ! -f volumes/kong/kong-template.yml ]; then
    echo "❌ No se encontró kong-template.yml"
    exit 1
fi

echo "✅ Verificación completada"
echo ""
echo "🎉 Configuración lista!"
echo ""
echo "Para iniciar Supabase localmente, ejecuta:"
echo "   docker-compose up -d"
echo ""
echo "Accede a los servicios:"
echo "   - Studio (Dashboard): http://localhost:3000"
echo "   - API: http://localhost:8000"
echo ""
echo "Para ver los logs:"
echo "   docker-compose logs -f"
