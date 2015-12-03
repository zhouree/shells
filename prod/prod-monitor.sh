#!/bin/bash

appDir=$HOME/app
maxLogTraceTime=50
gracefulShutdown=false
startCmds=(ti-hsm-simulator ti-quartz-srv ti-ttl-srv ti-s3-srv ac-common-srv ti-file-srv ti-dfs-srv ti-mns-common ti-bks-base ti-bks-ext ti-camel-srv ti-vault-srv ac-mon-srv ac-cif-srv ac-ums-srv ac-mns-srv ac-mds-srv ac-pas-srv ac-rcs-srv ac-rcs-cb-srv ac-tds-srv ac-cs-srv ac-txn-srv ac-txn-client-srv ac-bgw-sim ac-bgw-proxy-cil-pos ac-bgw-srv ac-tpz-srv ac-report-srv ac-tms-srv ac-vas-srv ac-vgw-proxy-cup-mcp ac-vgw-srv ac-pfs-srv ac-term-srv-vas ac-term-srv-apos ac-term-srv-base ac-term-srv-proxy ac-posp-srv ti-sock-proxy-srv ac-portal ac-test-web ti-monitor-business ti-monitor-sql-srv)

startProject() {
	curDir=`pwd`
	for cp in $@
	do
		printf ">> Start project"
		cf=${cp##*/} #Commond file
		cd=${cp%/*} #Commond dir
		
		cd $cd
		
		if [ -e nohup.out ]
		then
			mv nohup.out nohup.out.`date '+%Y%m%d.%H%M%S'`
		fi
		
		nohup ./$cf < /dev/null 1>nohup.out 2>&1 | echo ", begin..." &
		sleep 1s
		traceStartupLog $cd/nohup.out
		
		cd $curDir
	done
}

stopProject() {
	for cp in $@
	do
		printf ">> Stop project"
		cf=${cp##*/} #Commond file
		
		pids=`ps -ef | grep $cf | grep -v bash | grep -v grep | awk '{printf $2 " "}'`
		if [ "$pids" != "" ]
		then
			kill -3 $pids && printf ", dump thread info"
			sleep 2s #Wait thread dump
		
			if [ "$gracefulShutdown" == "true" ]
			then
				kill -TERM $pids && echo ", kill -TERM $pids"
			else
				kill -9 $pids && echo ", kill -9 $pids"
			fi
		else
			echo ", no running process found!"
		fi
	done
}

restartProject() {
	curDir=`pwd`
	for cp in $@
	do
		echo ">> Restart project, path=$cp"
		stopProject $cp
		startProject $cp
		
		cd $curDir
	done
}

traceStartupLog() {
	if test -e $1
	then
	  echo ">> Start tailing nohup file, path=$1"
	  tail -f $1 & tpid=$!
	  {
		for i in $(seq 1 $maxLogTraceTime)
		do
			lastLog=`tail -n 1 $1 | grep -i started`
			if [ "${lastLog}" != "" ]
			then
				kill -9 $tpid
				echo -e ">> Project start successful, elapsed time: ${i}s\n"
				break
			elif [ $i -eq $maxLogTraceTime ]
			then
				kill -9 $tpid
				echo -e ">> Project hasn't been started in past ${maxLogTraceTime}s, please check nohup file manually...\n"
				break
			fi
			sleep 1s
		done
	  }
	else
	  echo -e ">> Cannot find the nohup file, path=$1 \n"
	fi
}

tailNohup() {
	for cp in $@
	do
		echo ">> Start tailing nohup file, path=$cp"
		cf=${cp##*/} #Commond file
		cd=${cp%/*} #Commond dir
		
		tail -f $cd/nohup.out
	done
}

case "${1:-''}" in
	'list')
		echo "=== List projects ==="
		for cmd in ${startCmds[@]}
		do
			find $appDir -type f -name "$cmd" -printf '%CY/%Cm/%Cd %CH:%CM %s %p\n'
		done
		;;
		
	'check')
		kw=${2:-''} # key word 
		if [ "${kw}" == "" ]
		then
			echo ">> Please specify key word to check"
			exit 1
		elif [ "${kw}" == "-" ]
		then 
			echo "=== Check all projects ==="
			for cmd in ${startCmds[@]}
			do
				bash $0 check $cmd
			done
		else
			status=`ps aux|grep $kw|grep -v grep|grep -v bash`
			if [ "${#status}" == "0" ]
			then
				echo "$kw STOPPED!!!"
			else
				echo "$kw started"
			fi
		fi
		;;
		
	'start')
		cfn=${2:-''} # cmd file name
		if [ "${cfn}" == "" ]
		then
			echo "Please specify cmd file name to start"
			exit 1
		elif [ "${cfn}" == "-" ]
		then
			echo "=== Start all projects ==="
			for cmd in ${startCmds[@]}
			do
				bash $0 start $cmd
			done
		else
			echo "=== Start project $2 ==="
			cmds=`find $appDir -type f -name "$2" | grep -v ^\.$ `
			if [ "${#cmds}" == "0" ]
			then
				echo ">> Cannot find cmd file of project $2!!!"
				exit 1
			fi
			startProject $cmds
		fi
		;;
		
	'stop')
		cfn=${2:-''} # cmd file name
		if [ "${cfn}" == "" ]
		then
			echo ">> Please specify cmd file name to stop"
			exit 1
		elif [ "${cfn}" == "-" ]
		then
			echo "=== Stop all projects ==="
			for cmd in ${startCmds[@]}
			do
				bash $0 stop $cmd
			done
		else
			echo "=== Stop project $2 ==="
			cmds=`find $appDir -type f -name "$2" | grep -v ^\.$ `
			if [ "${#cmds}" == "0" ]
			then
				echo ">> Cannot find cmd file of project $2!!!"
				exit 1
			fi
			stopProject $cmds
		fi
		;;
		
	'restart')
		cfn=${2:-''} # cmd file name
		if [ "${cfn}" == "" ]
		then
			echo ">> Please specify cmd file name to restart"
			exit 1
		elif [ "${cfn}" == "-" ]
		then
			echo "=== Restart all projects ==="
			for cmd in ${startCmds[@]}
			do
				bash $0 restart $cmd
			done
		else
			echo "=== Restart project $2 ==="
			cmds=`find $appDir -type f -name "$2" | grep -v ^\.$ `
			if [ "${#cmds}" == "0" ]
			then
				echo ">> Cannot find cmd file of project $2!!!"
				exit 1
			fi
			restartProject $cmds
		fi
		;;
		
	'nohup')
		cfn=${2:-''} # cmd file name
		if [ "${cfn}" == "" ]
		then
			echo ">> Please specify cmd file name to tail nohup"
			exit 1
		else
			echo "=== Tail nohup of project $2 ==="
			cmds=`find $appDir -type f -name "$2" | grep -v ^\.$ `
			if [ "${#cmds}" == "0" ]
			then
				echo ">> Cannot find cmd file of project $2!!!"
				exit 1
			fi
			tailNohup $cmds
		fi
		;;
		
	*)
		echo "Usage: $0 list|check|start|stop|restart|nohup [name:???|-]"
		exit 1
		;;
esac