cat /proc/acpi/thermal_zone/THRM/temperature | sed -e "s/tempe.*:/CPU:/g" -e "s/  .*  /\t/g"
echo ""
DISPLAY=:0.0 nvidia-settings -q [gpu:0]/GPUCoreTemp -q [gpu:1]/GPUCoreTemp | grep "Attribute" | sed -e "s/.*:0\[//g" -e "s/\].: /\t/g" -e "s/\./ C/g" -e "s/gpu/GPU/g"