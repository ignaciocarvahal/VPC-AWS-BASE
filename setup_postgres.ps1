# Variables
$keyPath = "C:\Users\Usuario\Desktop\terraform\EC2\TNM-TOPUS.pem"
$publicIp = "18.144.1.101"
$privateIp = "10.0.2.219"
$scriptPathRemote = "/home/ubuntu/setup_postgres.sh"
$localScriptPath = "setup_postgres.sh"


# Contenido del script en formato Unix (LF)
$scriptContent = @"
#!/bin/bash
set -e

echo "Actualizando paquetes e instalando dependencias..."
sudo apt-get update -y
sudo apt-get install -y wget gnupg2 lsb-release

echo "Agregando repositorio oficial de PostgreSQL..."
echo "deb http://apt.postgresql.org/pub/repos/apt \$(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

echo "Actualizando lista de paquetes..."
sudo apt-get update -y

echo "Instalando PostgreSQL 16 y cliente..."
sudo apt-get install -y postgresql-16 postgresql-client-16

echo "Habilitando y arrancando PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "Configurando PostgreSQL para aceptar conexiones TCP/IP..."
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/16/main/postgresql.conf

echo "Configurando pg_hba.conf para permitir md5 en red privada..."
sudo tee /etc/postgresql/16/main/pg_hba.conf > /dev/null <<EOF
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             10.0.0.0/16             md5
EOF

echo "Reiniciando PostgreSQL para aplicar cambios..."
sudo systemctl restart postgresql

echo "Esperando a que PostgreSQL esté listo..."
until sudo pg_isready -h localhost -p 5432; do
  echo "PostgreSQL no está listo, esperando 3 segundos..."
  sleep 3
done

echo "Cambiando contraseña de usuario postgres..."
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'ignacio123';"

echo "Verificando existencia de la base de datos topusDB..."
DB_EXISTS=\$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='topusDB'")
if [ "\$DB_EXISTS" != "1" ]; then
  echo "Creando base de datos topusDB..."
  sudo -u postgres createdb topusDB
else
  echo "La base de datos topusDB ya existe, no se crea."
fi

echo "Configuración finalizada correctamente."
"@

# Guardar script sin CRLF (\r) usando Set-Content -NoNewline
$scriptContent | Set-Content -Path $localScriptPath -Encoding UTF8 -NoNewline

# Abrir túnel SSH y copiar el script al servidor privado a través del público
Write-Host "Copiando script a la instancia privada..."
scp -o StrictHostKeyChecking=no -i $keyPath -o ProxyCommand="ssh -i $keyPath -W %h:%p ubuntu@$publicIp" $localScriptPath ubuntu@$privateIp:$scriptPathRemote

# Ejecutar el script remotamente
Write-Host "Ejecutando script remotamente..."
ssh -i $keyPath -o ProxyCommand="ssh -i $keyPath -W %h:%p ubuntu@$publicIp" ubuntu@$privateIp "sudo bash $scriptPathRemote"

Write-Host "✅ Finalizado. PostgreSQL debería estar instalado y listo."
