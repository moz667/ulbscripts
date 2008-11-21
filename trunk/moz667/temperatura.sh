echo "============================================="
echo "* PLACA BASE : "
echo "---------------------------------------------"
cat /proc/acpi/thermal_zone/THRM/temperature | sed -e "s/tempe.*:/CPU/g" -e "s/  .*  /\t/g"
# El lmsensors da distintos resultados que lo que sale en la bios y en el nvidia settings, pero hay 2 temperaturas que no encuentro otra forma
# de sacar asi que...
# * Para que funcione tenemos que tener arrancado el demonio de lm_sensors, ver la instalacion/docu para mas detalle
sensors | grep Temp | grep -v "Core" | sed -e "s/°C.*/ C/g" -e "s/+//g" | grep -v "CPU" | sed -e "s/Temp3:       /Chipset\t/g" -e "s/M\/B Temp:    /Memoria\t/g"
echo ""
echo "============================================="
echo "* GRAFICAS : "
echo "---------------------------------------------"
DISPLAY=:0.0 nvidia-settings -q [gpu:0]/GPUCoreTemp -q [gpu:1]/GPUCoreTemp | grep "Attribute" | sed -e "s/.*:0\[//g" -e "s/\].: /\t/g" -e "s/\./ C/g" -e "s/gpu/GPU/g"
echo ""
echo "============================================="
echo "* DISCOS DUROS :"
echo "---------------------------------------------"
# Para ver la temperatura de los discos hay que configurar el hddtemp como daemon
# mas info /etc/conf.d/hddtemp
nc localhost 7634 | sed -e "s/||/\n/g" | sed -e "s/|/\t/g" | sed -e "s/^\t//g" | sed -e "s/\tC/ C/g"
echo ""
echo "============================================="
echo ""
