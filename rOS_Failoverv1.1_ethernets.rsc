#SET VARIABLES
:global host ""
:global ifaces 8
:global mIface "wlan1"
:global prefix "wlan"
:global gw 10.204.10.1
:global lanAddress 10.10.0.1
:global lanInterface "ether1"
:global ssid "WIFI_ETECSA"
:global rootRoute "$gw%$mIface"
for route from=2 to=$ifaces do={ :set $rootRoute ($rootRoute,"$gw%$prefix$route") }

#SET CLIENTS INTERFACES
interface wireless set $mIface ssid=$ssid disabled=no mode=station frequency-mode=superchannel country=no_country_set channel-width=20mhz wireless-protocol=802.11 station-roaming=disabled
for iface from=2 to=$ifaces  do={ interface wireless add ssid=$ssid master-interface=$mIface mode=station name="$prefix$iface" disabled=no }

#SET IP ADDRESS CONFIGURATION AND DHCP SERVER
:global startIP ($lanAddress + 1);
:global endIP (($lanAddress|0.0.0.255)-1);
ip address add address="$lanAddress/24" interface=$lanInterface
ip pool add name=LANsubnet ranges="$startIP-$endIP"
ip dhcp-server add address-pool=LANsubnet interface=$lanInterface lease-time=1d name=dhcpLAN disabled=no
ip dhcp-server network add address=(($lanAddress - 1)."/24") dns-server=$lanAddress gateway=$lanAddress netmask=24

#SET DHCP CLIENTS
for iface from=1 to=$ifaces do={ ip dhcp-client add interface="$prefix$iface" use-peer-dns=no use-peer-ntp=no disabled=no add-default-route=no }

#SET DNS SERVERS
ip dns set servers=181.225.231.110,181.225.231.120,181.225.233.30,181.225.233.40 allow-remote-requests=yes

#FIREWALL MANGLE
for rule from=1 to=$ifaces do={ ip firewall mangle add action=mark-routing new-routing-mark="$prefix$rule" src-address-list="$prefix$rule" chain=prerouting dst-address-type=!local passthrough=yes }
for rule from=1 to=$ifaces do={ ip firewall mangle add action=mark-connection new-connection-mark="$prefix$rule_conNTH" chain=prerouting passthrough=yes nth=1,1 disabled=yes src-address-list="full" dst-address-type=!local connection-mark=no-mark; ip firewall mangle add action=mark-routing new-routing-mark="$prefix$rule" connection-mark="$prefix$rule_conNTH" chain=prerouting src-address-list="full" passthrough=yes}
ip firewall mangle set comment="MARCADO DE RUTAS PARA CADA INTERFAZ >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" numbers=0; ip firewall mangle set comment="MARCADO DE CONEXIONES Y RUTAS PARA NTH  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" numbers=$ifaces

#FIREWALL NAT
for nat from=1 to=$ifaces do={ ip firewall nat add chain=srcnat action=masquerade routing-mark="$prefix$nat" out-interface="$prefix$nat" }

#ROUTES
for route from=1 to=$ifaces do={ ip route add gateway="$gw%$prefix$route" dst-address=0.0.0.0/0 routing-mark="$prefix$route" }
for route from=1 to=$ifaces do={ if ([$route]>9) do={:set host "1.1.1.1$route"} else={:set host "1.1.1.10$route"}; ip route add gateway="$gw%$prefix$route" dst-address="$host" }
ip route add gateway=$rootRoute dst-address=0.0.0.0/0 comment=for_router

#NETWATCH
for netw from=1 to=$ifaces do={ if ([$netw]>9) do={:set host "1.1.1.1$netw"} else={:set host "1.1.1.10$netw"}; tool netwatch add down-script="ip firewall mangle disable \
    [find new-connection-mark=$prefix$netw_conNTH and src-address-list=\"full\"];\r\
    \nsystem script run Failover;" host="$host" interval=5s timeout=3s \
    up-script="ip firewall mangle enable [find new-connection-mark=$prefix$netw_conNTH and\
    \_src-address-list=\"full\"];\r\
    \nsystem script run Failover;" }

#FAILOVER
system script add dont-require-permissions=yes name=Failover owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":local iface \"wlan1\";\r\
    \n:local steps 0;\r\
    \n:local tempSteps 1;\r\
    \n:local ruleIDs [/ip firewall mangle find new-connection-mark~\"_conNTH\"\
    \_and disabled=no];\r\
    \n:local steps ([:len \$ruleIDs ]);\r\
    \n:foreach ruleID in=\$ruleIDs do {\r\
    \n    ip firewall mangle set [find .id=\$ruleID] nth=\"\$steps,\$tempSteps\
    \";\r\
    \n    set tempSteps (\$tempSteps + 1);\r\
    \n}\r\
    \nif ([\$steps]=0) do {\r\
    \n    ip firewall address-list set [find comment~\"auto_\" and list=\"full\
    \"] list=\$iface;\r\
    \n} else {\r\
    \n    ip firewall address-list set [find comment~\"auto_\" and list=\$ifac\
    e] list=full;\r\
    \n}"


#PING ETECSA FOR EACH INTERFACE, IF IT DOESN'T RESPOND THEN RENEW THE IP
system script add dont-require-permissions=yes name=renewByPing owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="foreach iface in=[interface wireless registration-table find ap=yes] do {\r\
    \n    :local iName [interface wireless registration-table get value-name=interface [find .id=\$iface]];\r\
    \n    if ([ping 10.180.0.30 count=3 interface=\$iName]=0) do {\r\
    \n        ip dhcp-client renew [find interface=\$iName];\r\
    \n        log warning \"Renovando IP en interfaz \$iName\";\r\
    \n    }\r\
    \n}"

#SET RULE ROUTES FOR DNS
for rule from=1 to=$ifaces do={ ip route rule add dst-address=181.225.231.110/32 table="$prefix$rule" }
for rule from=1 to=$ifaces do={ ip route rule add dst-address=181.225.231.120/32 table="$prefix$rule" }
for rule from=1 to=$ifaces do={ ip route rule add dst-address=181.225.233.30/32 table="$prefix$rule" }
for rule from=1 to=$ifaces do={ ip route rule add dst-address=181.225.233.40/32 table="$prefix$rule" }

#FINISHING CONFIGURATION
foreach var in=[system script environment find] do={ system script environment remove $var }
system scheduler add name=init start-time=startup on-event="delay 5;\r\ \nsystem script run Failover;"
system scheduler add name=refreshInterface start-time=startup interval=1m on-event="system script run renewByPing;"
