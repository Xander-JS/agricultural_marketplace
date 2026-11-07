#!/usr/bin/env bash
set -e

# Generar .env si no existe a partir de las variables de entorno de Vercel
if [ ! -f .env ]; then
  cat <<EOF > .env
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
AI_API_KEY=${AI_API_KEY}
AI_ENDPOINT=${AI_ENDPOINT}
AI_MODEL=${AI_MODEL}
EOF
fi

# Instalar Flutter si no está disponible en el entorno
if ! command -v flutter >/dev/null 2>&1; then
  echo "Descargando Flutter SDK (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 _flutter
  export PATH="$PWD/_flutter/bin:$PATH"
fi

echo "Configurando Flutter y compilando para Web..."
flutter config --enable-web
flutter pub get
flutter build web --release
