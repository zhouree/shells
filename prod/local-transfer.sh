#!/bin/bash

buildUser=build
buildEnv=buildserver
buildDir=prod-build/java

prodEnv=${4:-'vas03'}
prodUser=${5:-'andpay'}

# kb/s
uploadLimit=1024
enableProdDeploy=0

fileType=$3
if [ "$fileType" == "war" ]
then
	fileType=".war"
else
	fileType="install.jar"
fi

downloadFiles() {
	for fp in $@
	do
		echo "Start download $buildEnv:$fp"
		scp $buildUser@$buildEnv:$fp install && echo "$buildEnv:$pn download successful"
	done
}

uploadFiles() {
	for fp in $@
	do
		echo "Start upload $prodEnv:$fp"
		if [ "$uploadLimit" != "0" ]
		then
			prod-deploy -b $uploadLimit $fp $prodUser@$prodEnv:install && echo "$prodEnv:$pn upload successful"
		else
			scp $fp $prodUser@$prodEnv:install && echo "$prodEnv:$pn upload successful"
		fi
	done
}

case "${1:-''}" in
	'list')
		echo "=== List $buildEnv packages ==="
		ssh -l $buildUser $buildEnv "find $buildDir -name *$fileType"
		;;
		
	'build')
		prefix=$2; test "$prefix" == "-" && prefix=''
		echo "=== Build $buildEnv $prefix* ==="
		ssh -l $buildUser $buildEnv "cd $buildDir && ./build.sh build $prefix"
		;;
		
	'down')
		prefix=$2; test "$prefix" == "-" && prefix=''
		echo "=== Download $buildEnv $prefix* ==="
		files=`ssh -l $buildUser $buildEnv "find $buildDir -name $prefix*$fileType"`
		if [ "${#files}" == "0" ]
		then
			echo "No file to download"
			exit 1;
		fi
		downloadFiles $files
		;;
		
	'up')
		prefix=$2; test "$prefix" == "-" && prefix=''
		echo "=== Upload $buildEnv $prefix* ==="
		files=`find install -name $prefix*$fileType`
		if [ "${#files}" == "0" ]
		then
			echo "No file to upload"
			exit 1;
		fi
		uploadFiles $files
		;;
		
	'tsf')
		prefix=$2; test "$prefix" == "-" && prefix=''
		echo "=== Transfer $buildEnv $prefix* ==="
		bash $0 down $2 $3
		bash $0 up $2 $3 $4
		;;
	
	'deploy')
		prefix=$2; test "$prefix" == "-" && prefix=''
		echo "=== Deploy $buildEnv $prefix* ==="
		bash $0 build $2
		bash $0 down $2 $3
		bash $0 up $2 $3 $4
		test "$enableProdDeploy" == "1" && ssh -l $prodUser $prodEnv "bash deploy.sh jar $2"
		;;
		
	*)
		echo "Usage: $0 list|down|up|tsf [prefix:???|-] [fileType:jar|war]"
		echo "Usage: $0 build|deploy [prefix:???|-]"
		exit 1;
		;;
esac