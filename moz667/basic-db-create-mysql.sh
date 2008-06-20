#!/bin/sh

# Crea una base de datos $1 y 
# un usuario u$1 con password $2 
# que solo tiene acceso a dicha bbdd localmente

# $1 Nombre de la bbdd local
# $2 Password de la bbdd local

echo "Creando Base de datos"

mysql -u root -e "CREATE DATABASE $1; \
GRANT USAGE ON * . * TO 'u$1'@'localhost' IDENTIFIED BY '$2' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 ; \
GRANT ALL PRIVILEGES ON $1 . * TO 'u$1'@'localhost' WITH GRANT OPTION ;" -p
