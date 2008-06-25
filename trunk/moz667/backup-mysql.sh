#!/bin/sh

# Hace copia de seguridad de todas las bases de datos mysql en $HOME/backup-mysql

AUX_FECHA="`date +%Y%m%d_%H%M`"
BBDDS=`mysqlshow | sed -e 's/\+.*//g' -e 's/.*Databases.*//g' -e 's/|//g' -e 's/ //g' | tr "\n" " " | sed -e 's/  //g' | sed -e 's/^ //' | tr " " "\n"`

for BBDD in $BBDDS
do
	mkdir -p ~/backup-mysql/$BBDD
	mysqldump $BBDD | bzip2 > ~/backup-mysql/$BBDD/$AUX_FECHA.sql.bz2
done
