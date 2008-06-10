#!/bin/sh

# $1, fichero video a pasar
# $2, imagen de marca de agua
# $3, fichero video resultante

ffmpeg -i $1 -vhook /usr/lib/vhook/watermark.so -f $2 -m 0 -t FF0000  -ar 22050 -ab 32 -f flv -s 320x240 $3
