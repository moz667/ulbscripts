#!/bin/sh

# $1 Archivo para convertir de unix a dos

awk 'sub("$", "\r")' $1 > $1-cnv
mv $1-cnv $1