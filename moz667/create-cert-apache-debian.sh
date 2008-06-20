#!/bin/sh

# Crea un certificado en /etc/apache/ssl
# $1 Nombre del archivo (.pem) destino para el certificado. 

mkdir -p  /etc/apache2/ssl

make-ssl-cert /usr/share/ssl-cert/ssleay.cnf /etc/apache2/ssl/$1
