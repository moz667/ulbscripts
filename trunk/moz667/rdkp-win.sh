#!/bin/sh

 # Crea una conexion por terminal services y crea una carpeta compartida en 
 # ~/share-rdkp
 
 mkdir -p ~/share-rdkp
  rdesktop -u administrador -g "85%" -r disk:share=~/share-rdkp $*