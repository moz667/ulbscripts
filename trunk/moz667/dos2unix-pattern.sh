#!/bin/sh

# $1 Patron que debe ir entre comillas dobles " y admite los mismos patrones que ls
# ejemplo : "/var/*.txt /tmp/dos* *.txt *.cfg"
# esto convertiria de formato dos a formato unix los archivos en /var/ terminados en .txt
# los de /tmp/ que empiecen por dos
# los que terminen en .txt y .xfg del directorio actual
#
# Requiere el script dos2unix

for file in `ls $1`
do
    dos2unix $file
done