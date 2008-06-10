# $1 Archivo para convertir de dos a unix

awk '{ sub("\r$", ""); print }' $1 > $1-cnv
mv $1-cnv $1