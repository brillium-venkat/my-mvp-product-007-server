#!/bin/bash
# ====================================================================================================================================
# appbrahma-build-and-run-server.sh
# AppBrahma server building and running
# Created by Venkateswar Reddy Melachervu on 15-03-2022.
# Updates:
#      16-03-2022 - Updated for mysql docker terminal spawning and running
# ====================================================================================================================================

# Required version values
GENERATOR_NAME="AppBrahma Backend Server"
GENERATOR_LINE_PREFIX=\[$GENERATOR_NAME]
EXIT_WRONG_PARAMS_ERROR_CODE=100
EXIT_DOCKER_NOT_INSTALLED_ERROR_CODE=101
EXIT_GNOME_TERMINAL_NOT_INSTALLED_ERROR_CODE=102
EXIT_NPM_INSTALL_ERROR_CODE=103
EXIT_WEBPACK_BUILD_INSTALL_ERROR_CODE=104
EXIT_MVNW_CHMOD_ERROR_CODE=105
EXIT_DELETE_TARGET_FOLDER_ERROR_CODE=106
EXIT_MVNW_CLEAN_ERROR_CODE=107

# arguments
# $1 - build/rebuild - rebuild cleans the target forcibly
# $2 - http/https

build_rebuild=$1
http_https=$2

clear

echo "=========================================================================================================================================="
echo "		Welcome to $GENERATOR_NAME build and run script"
echo "Sit back, relax, and sip a cuppa coffee while the dependencies are downloaded, project is built, and run."
echo "Unless the execution of this script stops, do not be bothered nor worried about any warnings or errors displayed during the execution ;-)"
echo "=========================================================================================================================================="

# args check
if [ $# -ne 2 ]; then
	echo "$GENERATOR_LINE_PREFIX : Invalid paramters supplied!"
  	echo "$GENERATOR_LINE_PREFIX : Usage: \"./apb-linux-server-build-n-run-mvn.sh build/rebuild http/https\""
  	exit $EXIT_WRONG_PARAMS_ERROR_CODE
fi

# gnome-terminal check
gnome_install_check=$(gnome-terminal -h 2>&1)
if [ $? -gt 0 ]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : gnome-terminal is not installed. Please install gnome-terminal and retry running this script."
	exit $EXIT_GNOME_TERMINAL_NOT_INSTALLED_ERROR_CODE
fi

# docker installation check
docker_install_check=$(docker-compose version 2>&1)
if [ $? -gt 0 ]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Docker-compose is not installed. Please install docker compose and retry running this script."
	exit $EXIT_DOCKER_NOT_INSTALLED_ERROR_CODE
fi

# As a pre-caution set the execute access permission to the mvnw script file
chmod_mvnw=$(chmod u+x ./mvnw 2>&1)
if [ $? -gt 0 ]; then
	echo "$GENERATOR_LINE_PREFIX : Error setting execute access permissions to mvnw.sh file. Error details are displated below. Please do it manually using the command and re-run this script."
	echo $chmod_mvnw
	exit $EXIT_MVNW_CHMOD_ERROR_CODE
fi

# build or rebuild
case $build_rebuild in
	*"build")		
		echo "$GENERATOR_LINE_PREFIX : Building backend web server project..."        
	;;
	*"rebuild")		
		echo "$GENERATOR_LINE_PREFIX : Re-building backend web server project..."
        delete_target=$(rm -rf target 2>&1)
		if [ $? -gt 0 ]; then
			echo "$GENERATOR_LINE_PREFIX : Error deleting the target folder for rebuilding. Error details are displated below. Please do it manually re-run this script."
			echo $delete_target
			exit $EXIT_DELETE_TARGET_FOLDER_ERROR_CODE
		fi		

		clean_mvnw=$(./mvnw clean)
		if [ $? -gt 0 ]; then
			echo "$GENERATOR_LINE_PREFIX : Error cleaning other build assets for re-building. Error details below."
			echo "Fix the errors and retry running this script."
			echo $clean_mvnw
			exit $EXIT_MVNW_CLEAN_ERROR_CODE
		fi		
	;;
	*"")		
		echo "$GENERATOR_LINE_PREFIX : Building backend web server project..."        
	;;
esac

echo "$GENERATOR_LINE_PREFIX : Installing backend server dependencies..."
apb_npm_install=$(npm install 2>&1)
if [ $? -gt 0 ]; then
	echo "$GENERATOR_LINE_PREFIX : Error installing node dependencies. Error details are displated below. Aborting the execution. Please retry running this script."
	echo $apb_npm_install
	exit $EXIT_NPM_INSTALL_ERROR_CODE
fi
echo "$GENERATOR_LINE_PREFIX : Installed backend server dependencies."

echo "$GENERATOR_LINE_PREFIX : Building front-end..."
apb_build_webpack=$(npm run webapp:build 2>&1)
if [ $? -gt 0 ]; then
	echo "$GENERATOR_LINE_PREFIX : Error building front-end code. Error details are displayed below. Aborting the execution."
	echo "Fix the errors and retry running this script."
	echo $apb_build_webpack
	exit $EXIT_WEBPACK_BUILD_INSTALL_ERROR_CODE
fi
echo "$GENERATOR_LINE_PREFIX : Built front-end."

# spawn docker terminal for mysql and run it
echo "$GENERATOR_LINE_PREFIX : Spawning a child terminal for running mysql in docker container..."
gnome-terminal --tab --title="AppBrahma - Docker - MySQL" -- bash -c 'printf "Welcome to AppBrahma backend server docker MySQL\n" && docker-compose -f src/main/docker/mysql.yml up --remove-orphans; exec bash'

case $http_https in
	*"https")		
		echo "$GENERATOR_LINE_PREFIX : Building and running spring boot java secured (https) web server..."
        ./mvnw -Ptls,dev
	;;
	*"http")		
		echo "$GENERATOR_LINE_PREFIX : Building and running spring boot java (http) web server..."
        ./mvnw
	;;
	*"")		
		echo "$GENERATOR_LINE_PREFIX : Building and running spring boot java (http) web server..."
        ./mvnw
	;;
esac
