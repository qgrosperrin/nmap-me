#!/bin/bash

##################
#      Menu      #
##################

usage() {
	
	echo " NmapMe (v 0.1) 																"
	echo " USAGE: ./nmap_me.sh -s [SIZE] -t [TARGET] -m [NB_SCANS] -n [NMAP_ARGS]	    "
	echo "																				"		
	echo " REQUIRED                                           							"
	echo "         -t  Target IP range.                									"
	echo "                                           									"
	echo " OPTIONAL                                           							"
	echo "         -s  Divide scans into chunk of maximum size specified. 				"
	echo "         -m  Maximum number of simultaneous scans              				"
	echo "         -n  Additional nmap arguments. Use surrounding quotes (\")      		"
	echo "         Default options include: -sS/-sU, -v. Both TCP and UDP scans  		"
	echo "         will be run against the target range.   								"
}

SIZE=
TARGET=
MAX_SCANS=
NMAP_ARGS=

while [[ $# > 1 ]]
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
	    -m)
		    MAX_SCANS="$1"
		    shift;;
	    -n)
			NMAP_ARGS="$1"
			shift;;
	    *)
	        printf "Invalid option: $0\n"
	        usage
	        exit 2;;
	esac
done

SIZE=${SIZE:-NULL}
TARGET=${TARGET:-NULL}
MAX_SCANS=${MAX_SCANS:-NULL}
NMAP_OPT=${NMAP_OPT:-""}

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

if [ $TARGET = NULL ]; then
	usage

else

	# Need to positively identify the session name:
	SESSION=mysession.$$
	echo "TO ATTACH TO SCREEN SESSION: screen -r ${SESSION}"

	# For signalling and stuff
	FLAGDIR=$(mktemp -d /tmp/foo.XXXXXX)

	# To keep the windows around after the commands are done,
	# set the "zombie" option (see the man-page)
	echo "source $HOME/.screenrc" > ${FLAGDIR}/screenrc
	echo "zombie xy" >> ${FLAGDIR}/screenrc

	echo ""
	echo -e "${green}[*]${NC} Launching Nmap scan(s)"

	screen -c ${FLAGDIR}/screenrc -d -m -S ${SESSION}

	if [ $SIZE = NULL ]; then		
		CMD_TCP="nmap -sS -v ${NMAP_ARGS} --open ${TARGET} -oA tcp-${TARGET}"
		CMD_UDP="nmap -sU -v ${NMAP_ARGS} --open ${TARGET} -oA udp-${TARGET}"

		screen -S ${SESSION} -X screen ${CMD_TCP}
		screen -S ${SESSION} -X screen ${CMD_UDP}

		screen -r ${SESSION}

	else
		if ! command -v sipcalc >/dev/null 2>&1; then
			echo -e "${red}[!]${NC} You don't have 'sipcalc' installed. You cannot use the '-s' functionality."
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
				CMD_TCP='echo "${RANGE}" | 
					awk -v var="${NMAP_ARGS}" {'"'"'print "nmap -sS -v -n "var" --open "$1" -oA tcp-"$1'"'"'}'
				CMD_UDP='(echo "${RANGE}" |
					awk -v var="${NMAP_ARGS}" {'"'"'print "nmap -sU -v -n "var" --open "$1" -oA udp-"$1'"'"'}'		

				while read -r line; do
	    			NB_SCANS=$(ps auxww | grep -v grep | grep "nmap " | wc -l) 
	    			echo -e "${yellow}[>]${NC} There are currently ${NB_SCANS} nmap scans running on your system." 

	    			if [ ! -z "${MAX_SCANS}" ] && (( "${NB_SCANS}" < "$MAX_SCANS" )); then
	    				echo -e "${yellow}[>]${NC} Running: ${line}"
	    				screen -S ${SESSION} -X screen ${line}
	    			elif [ -z "${MAX_SCANS}" ]; then
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
				done < <(eval $CMD_TCP)

				while read -r line; do
					NB_SCANS=$(ps auxww | grep -v grep | grep "nmap " | wc -l)
					echo "[>] There are currently ${NB_SCANS} nmap scans running on your system." 

	    			if [ ! -z "${MAX_SCANS}" ] && (( "${NB_SCANS}" < "$MAX_SCANS" )); then	
	    				echo -e "${yellow}[>]${NC} Running: ${line}"
	    				screen -S ${SESSION} -X screen ${line}
	    			elif [ -z "${MAX_SCANS}" ]; then
	    				echo -e "${yellow}[>]${NC} Runnig: ${line}"
	    				screen -S ${SESSION} -X screen ${line}
	    			else
	    				echo -e "${red}[!]${NC} too many scans running already. waiting to clear"
	    				while true; do
	    					NB_SCANS=$(ps auxww | grep -v grep | grep "nmap " | wc -l)
	    					if (( "${NB_SCANS}" < "$MAX_SCANS" )); then
	    						echo -e "${yellow}[>]${NC} Running: ${line}"
	    						screen -S ${SESSION} -X screen ${line}
	    						break
	    					fi
	    				done
	    			fi
				done < <(eval $CMD_UDP)
				
				#screen -r ${SESSION}

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