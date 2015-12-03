#!/bin/bash

vpnServer=113.106.92.230
tgtHost=192.168.21.1

vpnName=xgdvpn
maxTraceTime=20
configPath=/etc/xl2tpd/xl2tpd.conf

if test -e $configPath
then
	srvHost=`grep lns $configPath | sed 's/\s*lns\s*=\s*\([^\s]*\)\s*/\1/'`
else
	echo "l2tp config file doesn't exist, path=$configPath"
	exit 1
fi

isVpnStarted() {
	hasSrvRoute=`route -n | grep ppp | grep $srvHost`
	if [ "${#hasSrvRoute}" != "0" ]
	then
		echo 1
	else
		echo 0
	fi
}

getDefaultGateway() {
	echo `route -n | grep "0.0.0.0" | grep UG | grep eth0 | awk '{printf $2 " "}'`
}

startXl2tpd() {
	isXl2tpStart=`ps -ef | grep xl2tpd | grep -v grep`
	if [ "${#isXl2tpStart}" == "0" ]
	then
		/etc/init.d/xl2tpd start && echo "start xl2tpd"
	else
		echo "xl2tpd already started"
	fi
}

startVpn() {
	startXl2tpd

	echo "c $vpnName" > /var/run/xl2tpd/l2tp-control && echo "start xgd vpn, srvHost=$srvHost"
	traceVpnStatus 1 addRoute
}

stopVpn() {
	echo "d $vpnName" > /var/run/xl2tpd/l2tp-control && echo "stop xgd vpn, srvHost=$srvHost"
	traceVpnStatus 0
}

addRoute() {
	hasTgtRoute=`route -n | grep ppp | grep $tgtHost`
	if [ "${#hasTgtRoute}" == "0" ]
	then
		route add -host $tgtHost dev ppp0 && echo ">add $tgtHost ppp route successful"
	else
		echo ">$tgtHost ppp route already exists"
	fi

	defGw="$(getDefaultGateway)"
	hasVpnServerRoute=`route -n | grep $vpnServer | grep $defGw`
	if [ "${#hasVpnServerRoute}" == "0" ]
	then
		route add -host $vpnServer gw $defGw dev eth0 && echo ">add $vpnServer vpn server route successful"
	else
		echo ">$vpnServer vpn server route already exists"
	fi
}

traceVpnStatus() {
	echo ">start tracing vpn status"
	for i in $(seq 1 $maxTraceTime)
	do
		if [ "$(isVpnStarted)" == "$1" ]
		then
			echo ">operation succeed, elapsed time: ${i}s";
			
			if [ $# == 2 ] 
			then
				$2
			fi
			break;
			
		elif [ $i -eq $maxTraceTime ]
		then
			echo ">operation hasn't been completed in past ${maxTraceTime}s, please check it manually..."
			break;
		fi
		sleep 1s;
	done;
}

case "${1:-''}" in
	'start')
		echo "=== start xgd vpn ==="
		if [ "$(isVpnStarted)" == "1" ]
		then
			echo '>xgd vpn already started'
		else
			startVpn
		fi
		;;
		
	'stop')
		echo "=== stop xgd vpn ==="
		if [ "$(isVpnStarted)" == "0" ]
		then
			echo '>xgd vpn already stopped'
		else
			stopVpn
		fi
		;;
		
	'restart')
		echo "=== restart xgd vpn ==="
		$0 stop
		$0 start
		;;
		
	*)
		echo "Usage: $0 start|stop|restart"
		exit 1
		;;
esac