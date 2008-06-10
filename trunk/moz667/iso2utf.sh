#!/bin/sh

# $1 Archivo para convertir de ISO_8859-1 a UTF-8

cat $1 | iconv -f ISO_8859-1 -t UTF-8 >  cnv-$1
mv cnv-$1 $1
