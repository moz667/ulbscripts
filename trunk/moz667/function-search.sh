#!/bin/sh

# Busca una funcion entre los ficheros del directorio actual e hijos y edita el fichero con nano
# $1 funcion a buscar

FILE=`grep "function $1" * -l -R`
nano -w $FILE

