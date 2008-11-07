#!/bin/sh
# Prueba de comentario
# $1 Ruta absoluta al directorio para hacer backup en $HOME/backup

AUX_FECHA="`date +%Y%m%d_%H%M`"

mkdir -p ~/backup/$1

tar c -v $1 | bzip2 > ~/backup/$1/$AUX_FECHA.tar.bz2
