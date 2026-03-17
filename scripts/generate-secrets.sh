#!/bin/bash

# Script para generar secrets seguros para Supabase
# Uso: ./scripts/generate-secrets.sh

set -e

echo "🔐 Generando secrets para Supabase..."
echo ""

# Generar JWT_SECRET (32 bytes = 44 caracteres en base64)
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET=$JWT_SECRET"
echo ""

# Generar ANON_KEY (usando el mismo JWT_SECRET)
echo "ANON_KEY=$JWT_SECRET"
echo ""

# Generar SERVICE_ROLE_KEY (usando el mismo JWT_SECRET)
echo "SERVICE_ROLE_KEY=$JWT_SECRET"
echo ""

# Generar SECRET_KEY_BASE para Realtime (64 bytes = 88 caracteres en base64)
SECRET_KEY_BASE=$(openssl rand -base64 64)
echo "SECRET_KEY_BASE=$SECRET_KEY_BASE"
echo ""

# Generar LOGFLARE_API_KEY
LOGFLARE_API_KEY=$(openssl rand -hex 32)
echo "LOGFLARE_API_KEY=$LOGFLARE_API_KEY"
echo ""

# Generar POSTGRES_PASSWORD
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
echo ""

echo "✅ Secrets generados correctamente"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   1. Copia estos valores en tu archivo .env"
echo "   2. NUNCA compartas ni subas estos secrets a GitHub"
echo "   3. Guarda una copia segura de estos valores"
