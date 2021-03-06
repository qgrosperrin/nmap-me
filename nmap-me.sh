#!/usr/bin/env bash

##################
#      Menu      #
##################

usage() {
	
	echo " NmapMe (v 0.1b)"
	echo " USAGE: ./nmap_me.sh -t [TARGET] [OPTIONAL_ARGUMENTS]"
	echo " "		
	echo " REQUIRED"
	echo "         -t [TARGET]             Target IP range."
	echo "     OR"
	echo "         -iL [TARGET_FILE]       Use a list of target IP ranges (similar to nmap option)."
	echo " "
	echo " OPTIONAL"
	echo "         -s [SIZE]               Divide scans into chunk of maximum size specified."
	echo "         -m [MAX_SCANS]          Maximum number of simultaneous scans."
	echo "         -n [NMAP_ARGS]          Additional nmap arguments. Use surrounding quotes (\")."
	echo "                                 Hardcoded options include: -v, --open. Both TCP and UDP"
	echo "                                 scans will be run against the target range."
	echo "         --tcp-flag [TCP_FLAG]   Change TCP scanning method. Uses nmap flags (e.g. '-sT')."
	echo "                                 Default is '-sS' (SYN scan)."
	echo "         --no-tcp                Do not run TCP scans."
	echo "         --no-udp                Do not run UDP scans."
}

SCRIPT_PATH="$0"
VERSION="0.1 beta"

while [[ $# -ge 1 ]]
do
key="$1"
shift
	case $key in
	    	-s)
			SIZE="$1"
		    	shift;;
	    	-t)
		    	TARGET="$1"
		    	shift;;
		-iL) 	
			TARGET_FILE="$1"
			shift;;
	    	-m)
		    	MAX_SCANS="$1"
		    	shift;;
	    	-n)
			NMAP_ARGS="$1"
			shift;;
		--tcp-flag)
			TCP_FLAG="$1"
			shift;;
		--no-tcp)
			NO_TCP=true;;
                --no-udp)
                        NO_UDP=true;;
		*)
	        	printf "Invalid option: $0\n"
	        	usage
	        	exit 2;;
	esac
done

TCP_FLAG=${TCP_FLAG:-"-sS"}

######################
#   Output Coloring  #
######################
# Black        0;30     Dark Gray     1;30
# Blue         0;34     Light Blue    1;34
# Green        0;32     Light Green   1;32
# Cyan         0;36     Light Cyan    1;36
# Red          0;31     Light Red     1;31
# Purple       0;35     Light Purple  1;35
# Brown/Orange 0;33     Yellow        1;33
# Light Gray   0;37     White         1;37

green='\e[0;32m'
yellow='\e[1;33m'
red='\e[0;31m'
NC='\e[0m' 		# No Color

######################
#      Scanning      #
######################

if [ -z "${TARGET}" ] && [ -z "${TARGET_FILE}" ]; then
	usage

else
	# Check if we're root
	if [[ $EUID -ne 0 ]]; then
        	echo -e "${red}[!]${NC} Nmap may need to operate with elevated privileges for specific scan types (e.g. UDP, TCP SYN, etc). Run again with 'sudo'"
  	        echo -e "${red}[!]${NC} Exiting..."
		exit 1
	fi

	# Similar to '-iL' option in nmap. Recursive behaviour
	if ! [ -z "${TARGET_FILE}" ]; then 
		echo -e "${green}[*]${NC} Using target file: ${TARGET_FILE}"
		#cat $TARGET_FILE | grep -v "#" | xargs -L1 -I '{}' echo "${SCRIPT_PATH} -t {} -n ${NMAP_ARGS}"
		# TOFIX: need to fix arguments parsing
		cat $TARGET_FILE | grep -v "#" | xargs -L1 -I '{}' ${SCRIPT_PATH} -t '{}' -n "${NMAP_ARGS}"
		exit 0
	fi
	
	echo -e "${yellow}[>]${NC} Scanning target ${TARGET}"
	# Need to positively identify the session name:
	SESSION=nmap-me.$$
	echo "TO ATTACH TO SCREEN SESSION: screen -r ${SESSION}"
	# Verify that 'screen' is in installed and in the path
        if ! command -v screen >/dev/null 2>&1; then
        	echo -e "${red}[!]${NC} You don't have 'screen' installed. This tool requires it."
            echo -e "${red}[!]${NC} Exiting..."
            exit 1
	fi

	# For signalling and stuff
	FLAGDIR=$(mktemp -d /tmp/foo.XXXXXX)

	# To keep the windows around after the commands are done,
	# set the "zombie" option (see the man-page)
	echo "source $HOME/.screenrc" > ${FLAGDIR}/screenrc
	echo "zombie xy" >> ${FLAGDIR}/screenrc

	echo ""
	echo -e "${green}[*]${NC} Launching Nmap scan(s)"

	# TOFIX: when using '-iL', the script will create several screen sessions.
	# Ideally, we would just want one
	screen -c ${FLAGDIR}/screenrc -d -m -S ${SESSION}

	# Use-case for when no size is specified (i.e. no distribution of the range needed)
	if [ -z "${SIZE}" ]; then		
		
		if [[ $TARGET =~ [0-9\.]{4}/[0-9]{1,2} ]]; then
			TARGET_DIR="`echo "${TARGET}" | sed 's/\/[0-9]*//'`"
		else
			TARGET_DIR="${TARGET}"
		fi
	
		CMD_TCP="nmap ${TCP_FLAG} -v ${NMAP_ARGS} --open ${TARGET} -oA tcp-${TARGET_DIR}"
		CMD_UDP="nmap -sU -v ${NMAP_ARGS} --open ${TARGET} -oA udp-${TARGET_DIR}"

		if [ -z "${NO_TCP}" ]; then
			echo -e "${yellow}[>]${NC} Running: ${CMD_TCP}" 
			screen -S ${SESSION} -X screen ${CMD_TCP}		
		fi		

		if [ -z "${NO_UDP}" ]; then
			echo -e "${yellow}[>]${NC} Running: ${CMD_UDP}"
			screen -S ${SESSION} -X screen ${CMD_UDP}
		fi

	else
		# Verify that the target range is in IP format
		if [[ ! $TARGET =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*? ]]; then
			echo -e "${red}[!]${NC} You don't have specified a valid IP range. You cannot use the '-s' functionality."
			echo -e "${red}[!]${NC} Exiting..."
			exit 1

		# Verify that 'sipcalc' is in installed and in the path
		elif ! command -v sipcalc >/dev/null 2>&1; then
			echo -e "${red}[!]${NC} You don't have 'sipcalc' installed. You cannot use the '-s' functionality."
			echo -e "${red}[!]${NC} Exiting..."
			exit 1
		
		else
			RANGE=$(sipcalc ${TARGET} -s ${SIZE} | grep Network | awk '{print $3,$5}' | awk -F'[. ]' 'BEGIN{OFS=".";}{$5=$6=$7=""; print $0}' | sed 's/\.\.\.\./-/')
			echo -e "${yellow}[>]${NC} IP ranges chunks:"
			while read -r line; do
    			echo "	${line}"
			done <<< "${RANGE}"

			NB_PROCESS=$(echo "${RANGE}" | wc -l)
			echo -e "${green}[*]${NC} The target range was divided into $NB_PROCESS ranges of size ${SIZE}."
			
			if [ -z "${MAX_SCANS}" ]; then
				echo -e "${green}[*]${NC} This script will now create as many nmap processes."
			else
				echo -e "${green}[*]${NC} This script will now create maximum ${MAX_SCANS} simultaneous nmap processes."
			fi
			echo "Are you sure you want to continue ? [Y/n]"
			read ANSWER

			if [ -z "${ANSWER}" ] || [ "${ANSWER}" == 'Y' ] || [ "${ANSWER}" == 'y' ]; then
				CMD_TCP='echo "${RANGE}" | awk -v var="${NMAP_ARGS}" {'"'"'print "nmap '"'${TCP_FLAG}'"' -v "var" --open "$1" -oA tcp-"$1'"'"'}'
				CMD_UDP='echo "${RANGE}" | awk -v var="${NMAP_ARGS}" {'"'"'print "nmap -sU -v "var" --open "$1" -oA udp-"$1'"'"'}'		
				
				# Using function to simplify code.	
				__scan() {
					if [ $1 == "tcp" ]; then
						CMD=$CMD_TCP
					elif [ $1 == "udp" ]; then
						CMD=$CMD_UDP
					fi			
					
					while read -r line; do
                                	NB_SCANS=$(ps auxww | grep -v grep | grep "nmap " | wc -l) 
                                	echo -e "${yellow}[>]${NC} There are currently ${NB_SCANS} nmap scans running on your system." 

                                	if [ -z "${MAX_SCANS}" ]; then
                                        	echo -e "${yellow}[>]${NC} Running: ${line}"
                                        	screen -S ${SESSION} -X screen ${line}

                                	elif (( "${NB_SCANS}" < "$MAX_SCANS" )); then
                                        	echo -e "${yellow}[>]${NC} Running: ${line}"
                                        	screen -S ${SESSION} -X screen ${line}
                                	else
                                        	echo -e "${red}[!]${NC} too much scans already. waiting to clear"
                                        	while true; do
                                                	NB_SCANS=$(ps auxww | grep -v grep | grep "nmap " | wc -l)
                                                	if (( "${NB_SCANS}" < "$MAX_SCANS" )); then
                                                        	echo "[>] Running: ${line}"
                                                        	screen -S ${SESSION} -X screen ${line}
                                                        	break
                                                	fi
                                        	done
                                	fi
                                	done < <(eval $CMD)
				}

				if [ -z "${NO_TCP}" ]; then
					__scan tcp
				fi
				
				if [ -z "${NO_UDP}" ]; then
					__scan udp
				fi

			# If user does not want to continue.
			else
				exit 1

			fi
		fi
			
	fi
	
	echo -e "${green}[*]${NC} Done!!"

	# Don't need this any more:
	rm -rf ${FLAGDIR}

fi

exit
