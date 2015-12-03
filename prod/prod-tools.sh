#!/bin/bash

oper=andpay
pgkDir=$HOME/install
appDir=$HOME/app
backupDir=$HOME/backup
rollbackDir=$HOME/rollback
localDownloadDir=download

# server(ip|hostname)  
allVas=('10.146.10.105|vas01' '10.146.10.106|vas02' '10.146.10.107|vas03' '10.146.10.108|vas04' '10.146.10.141|vas05' '10.146.10.142|vas06' '10.146.10.143|vas07' '10.146.10.144|vas08' '10.146.10.145|vas09' '10.146.10.146|vas10' '10.146.10.147|vas11' '10.146.10.148|vas12' '10.146.10.124|cfapp01' '10.146.10.125|cfapp02')
allWeb=('10.146.10.126|web01' '10.146.10.127|web02')
allVms=('10.146.10.103|vms01' '10.146.10.104|vms02')
allVws=('10.146.128.20|vws01' '10.146.128.21|vws02' '10.146.128.22|vws03' '10.146.128.23|vws04')
allShcs=('172.19.30.111|shcs111' '172.19.30.112|shcs112' '172.19.30.114|shcs114' '172.19.30.119|shcs119' '172.19.30.120|shcs120')

listJavaProc() {
	ost=`echo $1 | cut -d '|' -f 1` #host
	doLog=${2:-''}
	shell="ps aux|grep java|grep -v bash|grep -v grep"

	sshShell $oper $host "$shell" $doLog
}

listHosts() {
	host=`echo $1 | cut -d '|' -f 1` #host
	doLog=${2:-''}
	shell="cat /etc/hosts"

	sshShell $oper $host "$shell" $doLog 
}

updateHosts() {
	host=`echo $1 | cut -d '|' -f 1` #host
	hostDef=$2
	doLog=${3:-''}
	shell="sudo -s vi /etc/hosts"
	
	ssh -tt $oper@$host "$shell"
}

updateNsConfig() {
	host=`echo $1 | cut -d '|' -f 1` #host
	nsPath=$2
	doLog=${3:-''}
	scp -r ns/$nsPath/* $oper@$host:.ns_config/$nsPath
}

doTelnet() {
	host=`echo $1 | cut -d '|' -f 1`
	tgtHost=`echo $2 | cut -d ':' -f 1`
	tgtPort=`echo $2 | cut -d ':' -f 2`
	shell="telnet $tgtHost $tgtPort"

	sshShell $oper $host "$shell"
}

shutdownApp() {
	host=`echo $1 | cut -d '|' -f 1`
	appName=$2
	shell="./monitor.sh stop $appName"

	sshShell $oper $host "$shell"
}

restartApp() {
	host=`echo $1 | cut -d '|' -f 1`
	appName=$2
	shell="./monitor.sh restart $appName"

	sshShell $oper $host "$shell"
}

downloadFile() {
	mkdir -p $localDownloadDir

	host=`echo $1 | cut -d '|' -f 1`
	fPath=$2
	scp $oper@$host:$2 "$localDownloadDir/$host.${fPath##*/}"
}

uploadFile() {
	host=`echo $1 | cut -d '|' -f 1`
	fromPath=$2
	toPath=$3
	scp $fromPath $oper@$host:$toPath
}

sshShell() {
	user=$1
	host=$2
	shell=$3
	doLog=${4:-''}
	
	if [ "$doLog" == "Y" ]
	then
		mkdir -p log
		ssh $user@$host "$shell" > log/$host.log
	else
		ssh $user@$host "$shell"
	fi	
}

case "${1:-''}" in
	'jp')
		host=${2:-''}
		doLog=${3:-''}
		case "$host" in
			'')
				echo "Usage: $0 jp \$host|vas|vws|web [Y|N] #List Java Process"
				;;
			'vas')
				echo "=== List java processes on vas servers ==="
				for vs in ${allVas[@]}
				do
					bash $0 jp $vs $doLog
				done
				;;
			'vws')
				echo "=== List java processes on vws servers ==="
				for vs in ${allVws[@]}
				do
					bash $0 jp $vs $doLog
				done
				;;
			'web')
				echo "=== List java processes on web servers ==="
				for vs in ${allWeb[@]}
				do
					bash $0 jp $vs $doLog
				done
				;;
			*)
				echo "=== List java processes on $host ==="
				listJavaProc $host $doLog
				;;
			esac
		;;
		
	'hs')
		host=${2:-''}
		doLog=${3:-''}
		case "$host" in
			'')
				echo "Usage: $0 hs \$host|vas|vws|web [Y|N] #List Hosts"
				;;
			'vas')
				echo "=== List hosts on vas servers ==="
				for vs in ${allVas[@]}
				do
					bash $0 hs $vs $doLog
				done
				;;
			'vws')
				echo "=== List hosts on vws servers ==="
				for vs in ${allVws[@]}
				do
					bash $0 hs $vs $doLog
				done
				;;
			'web')
				echo "=== List hosts on web servers ==="
				for vs in ${allWeb[@]}
				do
					bash $0 hs $vs $doLog
				done
				;;
			*)
				echo "=== List hosts on $host ==="
				listHosts $host $doLog
				;;
			esac
		;;
		
	'uhs')
		host=${2:-''}
		case "$host" in
			'')
				echo "Usage: $0 uhs \$host|vas|vws|web #Update Hosts"
				;;
			'vas')
				echo "=== Update hosts on vas servers ==="
				for vs in ${allVas[@]}
				do
					bash $0 uhs $vs
				done
				;;
			'vws')
				echo "=== Update hosts on vws servers ==="
				for vs in ${allVws[@]}
				do
					bash $0 uhs $vs
				done
				;;
			'web')
				echo "=== Update hosts on web servers ==="
				for vs in ${allWeb[@]}
				do
					bash $0 uhs $vs
				done
				;;
			*)
				echo "=== Update hosts on $host ==="
				updateHosts $host
				;;
			esac
		;;
		
	'uns')
		host=${2:-''}
		nsPath=${3:-''}
		doLog=${4:-''}
		case "$host" in
			'')
				echo "Usage: $0 uns \$host|vas|vws|web \$nsPath [Y|N] #Update NsConfig"
				;;
			'vas')
				echo "=== Update nsConfig on vas servers ==="
				for vs in ${allVas[@]}
				do
					bash $0 uns $vs $nsPath $doLog
				done
				;;
			'vws')
				echo "=== Update nsConfig on vws servers ==="
				for vs in ${allVws[@]}
				do
					bash $0 uns $vs $nsPath $doLog
				done
				;;
			'web')
				echo "=== Update nsConfig on web servers ==="
				for vs in ${allWeb[@]}
				do
					bash $0 uns $vs $nsPath $doLog
				done
				;;
			*)
				echo "=== Update nsConfig on $host ==="
				updateNsConfig $host $nsPath $doLog
				;;
			esac
		;;
		
	'tn')
		host=${2:-''}
		hap=${3:-''}
		doLog=${4:-''}
		case "$host" in
			'')
				echo "Usage: $0 tn \$host \$target:\$port [Y|N] #Telnet"
				;;
			*)
				echo "=== Telnet on $host ==="
				doTelnet $host $hap $doLog
				;;
			esac
		;;
		
	'sda')
		host=${2:-''}
		appName=${3:-''}
		doLog=${4:-''}
		case "$host" in
			'')
				echo "Usage: $0 sda \$host \$appName [Y|N] #Shutdown app"
				;;
			*)
				echo "=== Stop app $appName on $host ==="
				shutdownApp $host $appName $doLog
				;;
			esac
		;;
	'rsa')
		host=${2:-''}
		appName=${3:-''}
		doLog=${4:-''}
		case "$host" in
			'')
				echo "Usage: $0 rsa \$host \$appName [Y|N] #Restart app"
				;;
			*)
				echo "=== Restart app $appName on $host ==="
				restartApp $host $appName $doLog
				;;
			esac
		;;
		
	'df')
		host=${2:-''}
		fPath=${3:-''}
		case "$host" in
			'')
				echo "Usage: $0 df \$host|vas|vws|web \$fPath #Download file"
				;;
			'vas')
				echo "=== Download file $fPath on vas servers ==="
				for vs in ${allVas[@]}
				do
					bash $0 df $vs $fPath
				done
				;;
			'vws')
				echo "=== Download file $fPath on vws servers ==="
				for vs in ${allVws[@]}
				do
					bash $0 df $vs $fPath
				done
				;;
			'web')
				echo "=== Download file $fPath on web servers ==="
				for vs in ${allWeb[@]}
				do
					bash $0 df $vs $fPath
				done
				;;
			'shcs')
				echo "=== Download file $fPath on shcs servers ==="
				for vs in ${allShcs[@]}
				do
					bash $0 df $vs $fPath
				done
				;;
			*)
				echo "=== Download file $fPath on $host ==="
				downloadFile $host $fPath
				;;
			esac
		;;
		
	'uf')
		host=${2:-''}
		localPath=${3:-''}
		remotePath=${4:-''}
		case "$host" in
			'')
				echo "Usage: $0 uf \$host|vas|vws|web \$localPath \$remotePath #Upload file"
				;;
			'vas')
				echo "=== Upload file $localPath on vas servers $remotePath ==="
				for vs in ${allVas[@]}
				do
					bash $0 uf $vs $localPath $remotePath
				done
				;;
			'vws')
				echo "=== Upload file $localPath on vws servers $remotePath ==="
				for vs in ${allVws[@]}
				do
					bash $0 uf $vs $localPath $remotePath
				done
				;;
			'web')
				echo "=== Upload file $localPath on web servers $remotePath ==="
				for vs in ${allWeb[@]}
				do
					bash $0 uf $vs $localPath $remotePath
				done
				;;
			'shcs')
				echo "=== Upload file $localPath on shcs servers $remotePath ==="
				for vs in ${allShcs[@]}
				do
					bash $0 uf $vs $localPath $remotePath
				done
				;;
			*)
				echo "=== Upload file $localPath on $host:$remotePath ==="
				uploadFile $host $localPath $remotePath
				;;
			esac
		;;
	*)
		echo "Usage: 1) $0 jp \$host|vas|vws|web [Y|N] #List Java Process"
		echo "Usage: 2) $0 hs \$host|vas|vws|web [Y|N] #List Hosts"
		echo "Usage: 3) $0 uhs \$host|vas|vws|web #Update Hosts"
		echo "Usage: 4) $0 uns \$host|vas|vws|web \$nsPath [Y|N] #Update NsConfig"
		echo "Usage: 5) $0 tn \$host \$target:\$port #Telnet"
		echo "Usage: 6) $0 sda \$host \$target:\$port #Shutdown app"
		echo "Usage: 7) $0 rsa \$host \$target:\$port #Restart app"
		echo "Usage: 8) $0 df \$host|vas|vws|web \$fPath #Download file"
		echo "Usage: 9) $0 uf \$host|vas|vws|web \$localPath \$remotePath #Upload file"
		exit 1
		;;
esac