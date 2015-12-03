#!/bin/bash

env=${3:-stage0}
deployServer=stage0
buildDir=.
buildOrders=(ti-base ti-daf ti-seq ti-util ti-srv-util ti-srv-config ti-srv-redis-util ti-cache ti-test ti-lnk ti-queue ti-proxy ac-const ac-common ti-quartz ti-ttl ti-s3 ti-sock ti-sock-proxy ti-hsm-simulator ti-file-srv ti-dfs ti-mns ti-bks ti-camel ti-dte ac-mon ac-acct ac-cif ac-ums ac-mns ac-mds ac-rcs ac-tds ac-cs ac-pas ac-txn ac-txn-client ac-bgw ac-tpz ac-report ac-tms ac-term ac-term-srv ac-posp ac-remote ac-portal ac-test-web ti-monitor)
jarDeployOrders=(ti-quartz ti-ttl ti-s3 ac-common ti-hsm-simulator ti-file-srv ti-dfs ti-mns-common ti-bks-base ti-bks-ext ti-camel ac-mon ac-cif ac-ums ac-mns ac-mds ac-rcs-srv ac-rcs-cb-srv ac-tds ac-cs ac-pas ac-txn-srv ac-tpz-srv ac-report ac-txn-client ac-bgw-sim ac-bgw-proxy-cil-pos ac-bgw-srv ac-tms ac-term-srv-apos ac-term-srv-base ac-term-srv-proxy ac-posp-srv ti-sock-proxy ti-monitor-business ti-monitor-sql-srv)
warDeployOrders=(ac-portal ac-test-web)

syncProject() {
	curDir=`pwd`
	for fp in $@
	do
		echo ">start sync $fp"
		cd $fp && git pull
		cd $curDir
	done
}

buildProject() {
	curDir=`pwd`
	for fp in $@
	do
		echo ">start build $fp"
		cd $fp && git pull && mvn clean deploy -Dmaven.test.skip=true
		cd $curDir
	done
}

deploy() {
	for fp in $@
	do
		scp $fp andpay@$deployServer:install
		
		fn=${fp##*/} #fileName
		fs=${fp##*.} #fileSuffix
		pn=`echo $fn | sed 's/\(.*\)-[0-9]\{1,\}\..*/\1/'` #projectName
		
		ssh -t -x -landpay $deployServer "./deploy.sh $fs $pn"
	done
}

case "${1:-''}" in
	'list')
		echo "=== List projects ==="
		find $buildDir -maxdepth 1 -type d
		;;
		
	'sync')
		prefix=${2:-''}; 
		if [ "${prefix}" == "-" ]
		then
			echo "=== Sync all projects ==="
			for pkg in ${buildOrders[@]}
			do
				bash $0 sync $pkg
			done
		else
			echo "=== Sync project $2* ==="
			projs=`find $buildDir -maxdepth 1 -type d -name "$2*" | grep -v ^\.$ `
			if [ "${#projs}" == "0" ]
			then
				echo "No project to sync"
				exit 1
			fi
			syncProject $projs
		fi
		;;
		
	'build')
		prefix=${2:-''}; 
		if [ "${prefix}" == "-" ]
		then
			echo "=== Build all projects ==="
			for pkg in ${buildOrders[@]}
			do
				bash $0 build $pkg
			done
		else
			echo "=== Build project $2* ==="
			projs=`find $buildDir -maxdepth 1 -type d -name "$2*" | grep -v ^\.$ `
			if [ "${#projs}" == "0" ]
			then
				echo "No project to build"
				exit 1
			fi
			buildProject $projs
		fi
		;;
		
	'deploy')
		prefix=${2:-''};
		pkgType=${3:-'jar'} 
		if [ "${prefix}" == "-" ]
		then
			echo "=== Deploy all jar|war ==="
			for pkg in ${jarDeployOrders[@]}
			do
				bash $0 deploy $pkg jar
			done
			
			for pkg in ${warDeployOrders[@]}
			do
				bash $0 deploy $pkg war
			done
		else
			echo "=== Deploy $prefix* ==="
			if [ "$pkgType" == "war" ]
			then
				files=`find $pgkDir -name "$prefix*.war"` #filePath
			else
				files=`find $pgkDir -name "$prefix*install.jar"` #filePath
			fi
			if [ "${#files}" == "0" ]
			then
				echo "no file to deploy"
				exit 1;
			fi
			deploy $files
		fi
		;;
		
	'clean')
		find . -regex '.*/build/.*\.[jw]ar' -exec rm -rf {} \;
		find . -regex '.*/target/.*\.[jw]ar' -exec rm -rf {} \;
		;;
		
	*)
		echo "Usage: $0 list|sync|build|deploy|clean [prefix:???|-] [jar|war]"
		exit 1;
		;;
esac