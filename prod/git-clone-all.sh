#!/bin/bash
GIT_SERVER=192.168.1.110
BASE_DIR=prod-build
JAVA_PCP='ti|ac|mt|base-pom.git' #project category pattern
RUBY_PCP='ruby'
DEVOPS_PCP='devOps'
OTHER_PCP='NO_PC'
SEARCH_MAX_DEPTH=3
LOG_IGNORED_GIT_PATH=0

gitClone() {
	curDir=`pwd`

	for gpp in $@
	do
	  pc=`echo $gpp | sed 's/\.\/\(.*\)\/.*/\1/'` #project category
	  
	  if [[ "$pc" =~ $JAVA_PCP ]] ;then
	  	 pc='java'
	  elif [[ "$pc" =~ $RUBY_PCP ]] ;then
	  	 pc='ruby'
	  elif [[ "$pc" =~ $DEVOPS_PCP ]] ;then
	  	 pc='devOps'
	  elif [[ "$pc" =~ $OTHER_PCP ]] ;then
	  	 pc='other'
	  else
	  	 test $LOG_IGNORED_GIT_PATH -eq 1 && echo ">ignore project git@$GIT_SERVER:$gpp"
	  	 continue
	  fi
	  
	  pc=$BASE_DIR/$pc
	  
	  test ! -d $pc && mkdir -p $pc
	  cd $pc && echo ">cloning project git@$GIT_SERVER:$gpp to $pc" && git clone git@$GIT_SERVER:$gpp
	  cd $curDir
	done
}

gitClone `ssh -l git $GIT_SERVER "find . -maxdepth $SEARCH_MAX_DEPTH -type d -regex \".*[^/]\.git\""`