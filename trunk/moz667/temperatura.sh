cat /proc/acpi/thermal_zone/THRM/temperature | sed -e "s/tempe.*:/CPU:/g" -e "s/  .*  /\t/g"
echo ""
DISPLAY=:0.0 nvidia-settings -q [gpu:0]/GPUCoreTemp -q [gpu:1]/GPUCoreTemp | grep "Attribute" | sed -e "s/.*:0\[//g" -e "s/\].: /\t/g" -e "s/\./ C/g" -e "s/gpu/GPU/g"
# Discos duros
echo ""
# Para ver la temperatura de los discos hay que configurar el hddtemp como daemon
# mas info /etc/conf.d/hddtemp
nc localhost 7634 | sed -e "s/||/\n/g" | sed -e "s/|/\t/g" | sed -e "s/^\t//g" | sed -e "s/\tC/ C/g"
echo ""
