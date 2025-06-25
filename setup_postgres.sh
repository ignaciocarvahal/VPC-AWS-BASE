#!/bin/bash

set -e

# 1. Añadir repositorio oficial PostgreSQL 16

# Importar la clave pública
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/postgresql.asc

# Añadir repositorio para Ubuntu 20.04 focal (ajusta si es otra versión)
echo "deb http://apt.postgresql.org/pub/repos/apt focal-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

# 2. Actualizar repositorios
sudo apt update

# 3. Instalar PostgreSQL 16
sudo apt install -y postgresql-16 postgresql-client-16 postgresql-contrib-16

# 4. Crear cluster PostgreSQL 16 si no existe (crea configuración y data)
if [ ! -d "/etc/postgresql/16/main" ]; then
  sudo pg_createcluster 16 main --start
fi

# 5. Habilitar e iniciar servicio PostgreSQL 16
sudo systemctl enable postgresql
sudo systemctl start postgresql

PG_VERSION="16"
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

# 6. Configurar listen_addresses para aceptar conexiones remotas
sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# 7. Añadir regla pg_hba.conf para permitir conexiones de red 10.0.0.0/16
sudo grep -qxF "host    all             all             10.0.0.0/16           md5" "$PG_HBA" || \
  echo "host    all             all             10.0.0.0/16           md5" | sudo tee -a "$PG_HBA"

# 8. Reiniciar PostgreSQL para aplicar cambios
sudo systemctl restart postgresql

# 9. Crear usuario y base de datos, con control para no repetir
sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres') THEN
      CREATE ROLE postgres LOGIN PASSWORD 'ignacio';
   ELSE
      ALTER ROLE postgres WITH PASSWORD 'ignacio';
   END IF;
END
\$do\$;

SELECT
  CASE WHEN NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'topusDB'
  ) THEN
    'CREATE DATABASE "topusDB" OWNER postgres'::text
  ELSE
    'SELECT 1'::text
  END
\gexec
EOF

echo "PostgreSQL 16 instalado y configurado correctamente."
echo "Usuario: postgres"
echo "Base de datos: topusDB"
echo "Contraseña: ignacio"