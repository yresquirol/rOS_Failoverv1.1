# rOS_Failover V1.1
Configura Mikrotik para multi WAN + balanceo NTH + failover

<b>Para descargar use el botón verde de arriba a la derecha (Clone or download)</b>

Este script te permite configurar tu MikroTik (si tiene licencia L4) para hacer multi WAN (lo que se conoce como multi portales) además, ofrece balanceo para los usuarios (IP) que pertenezcan a la lista "wlan1" aplicando failover sobre las interfaces.

<b>Como usar el script:</b>
<b>Primero lo primero: Bajar el archivo script.rsc y editarlo para configurar las variables necesarias según la descripción de abajo.</b>

:global ifaces 8; ---->>>>> es la cantidad de interfaces y cantidad de WAN's (portales) que queremos <b>(cambiar el 8 por la cantidad de interfaces deseadas).</b>

:global mIface "wlan1"; ---->>>>> es el nombre de la interfaz inalámbrica física (puedes cambiarlo o dejarlo asi... solo cambia lo que está entre "") <b>Si modifican esta variable, antes de comenzar a pegar el script en el MikroTik hay que cambiar el nombre de la interfaz inalámbrica por el nombre que escriban aquí. </b>

:global prefix "wlan"; ---->>>>>> es el prefijo que tendrán las interfaces, tener en cuenta que el prefijo tiene que ser el mismo de la variable mIface sin el número <b>(cambiar solo lo que está entre "" si modifican la variable de arriba).</b>

:global gw 10.204.10.1; ----->>>>>>> es el gateway/puerta de enlace que les asigna ETECSA. Este IP varía así que deben averiguar primero cual es (cambiar solo el IP).

:global lanAddress 10.10.0.1; ----->>>>>> es el ip que queremos asignarle a la LAN del Mikrotik. <b>Elijan siempre un IP con .1 al final, ejemplo 172.16.0.1 o 192.168.100.1.</b>

:global ssid "WIFI_ETECSA" --->>>>>> por su puesto este es el SSID de los AP de ETECSA. Si te conectas a traves de un hotel u otro establecimiento que tenga otro nombre puedes cambiarlo <b>(solo lo que esta entre "").</b>

<b>Te recomiendo usar el video como guía luego de haber editado el script y configurado las variables.</b>
<b>Video:<b> https://youtu.be/FjWB87W_Uao
