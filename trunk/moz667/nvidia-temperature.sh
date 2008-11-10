# Explicaciones varias :
# DISPLAY=:0.0 (solo es necesario si lo estas lanzando desde  una consola remota)
# nvidia-settings -q (ejecuta una consulta, mirar nvidia-settings --help)
# [gpu:0]/GPUCoreTemp (La consulta, algo asi como dame la temperatura de la gpu 0)
# -q [gpu:1]/GPUCoreTemp (necesario si tenemos 2 tarjetas graficas...)
# | grep "Attribute" (filtra la salida para que solo muestre las lineas que tienen "Attribute")
# | sed -e "s/.*: //g" -e "s/\.//g" (unos pequeños replaces para que aparedca solo la temperatura)

DISPLAY=:0.0 nvidia-settings -q [gpu:0]/GPUCoreTemp -q [gpu:1]/GPUCoreTemp | grep "Attribute" | sed -e "s/.*: //g" -e "s/\.//g"