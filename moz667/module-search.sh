# Busca el modulo que le pasamos como parametro

echo "======== Compilados en /lib/modules ================"
find /lib/modules/ -iname '*.o' -or -iname '*.ko' |grep $1
echo "======== Codigo de /usr/src =================="
find /usr/src/ -iname '*.c' -or -iname '*.h' |grep $1
