_currently in beta_

Description
===========
This is a basic BASH script designed to help automate and manage `nmap` scans. 

The script provides the ability to separate the target range into smaller subnets to help reduce overhead when scanning big network ranges. Each individual `nmap` scan receives its own `screen` window within a common `screen` session, further allowing the scans to be segregated and resilient to shell disruption (e.g. via SSH). 

Depending on the size of each resulting subnet, specified in the CLI using the '-s' argument, the script could create a huge number of `nmap` processes, potentially affecting the stability and availability of the target. As a result, the '-m' option can be leveraged to specify the maximum number of simultaneous `nmap` scans that should be running on the system. Upon reaching the maximum number specified (unlimited if un-specified), the script will wait for running nmap scans to finish before launching a new scan.

__Note__: at the moment, the script does not make any difference between your `nmap` scans launched by the tool, and other `nmap` scans launched in the background by other users. This is a known bug. If additional scans are running on the system, it may therefore limit the tool in his ability to launch new scans.


Usage
=====
This script requires both __nmap__ and __sipcalc__ (used by the '-s' option) to be installed on the system.

```
 NmapMe (v 0.1) 
 USAGE: ./nmap_me.sh -s [SIZE] -t [TARGET] -m [NB_SCANS] -n [NMAP_ARGS]

 REQUIRED                                           
         -t  Target IP range.                
                                           
 OPTIONAL                                           
         -s  Divide scans into chunk of maximum size specified. 
         -m  Maximum number of simultaneous scans              
         -n  Additional nmap arguments. Use surrounding quotes (")
             Default options include: -sS/-sU, -v, -n--open
```

Standard nmap TCP command used by the script:   
`nmap -sS -v -n ${nmap_args} --open ${target_subrange} -oA tcp-${target_subrange}`   
Standard nmap UDP command used by the script:   
`nmap -sU -v -n ${nmap_args} --open ${target_subrange} -oA udp-${target_subrange}`   

Where `${nmap_args}` will be replaced by any additional `nmap` arguments specified using the '-n' option, and `${target_subrange}` will be replaced by a calculated subrange of the target specified in the CLI.


__Example output:__
```
# ./nmap-me.sh -s /24 -t 192.168.25.0/20 -m 5                                                    
TO ATTACH TO SCREEN SESSION: screen -r mysession.28805

[*] Launching Nmap scan(s)
[>] IP ranges chunks:
        192.168.16.0-255
        192.168.17.0-255
        192.168.18.0-255
        192.168.19.0-255
        192.168.20.0-255
        192.168.21.0-255
        192.168.22.0-255
        192.168.23.0-255
        192.168.24.0-255
        192.168.25.0-255
        192.168.26.0-255
        192.168.27.0-255
        192.168.28.0-255
        192.168.29.0-255
        192.168.30.0-255
        192.168.31.0-255
[*] The target range was divided into 16 ranges of size /24.
[*] This script will now create as many processes, are you sure you want to continue ? [Y/n]
Y
[>] There are currently 0 nmap scans running on your system.
[>] Running: nmap -sS -v -n -p 80 --open 192.168.16.0-255 -oA full-tcp-192.168.16.0-255
[>] There are currently 1 nmap scans running on your system.
[>] Running: nmap -sS -v -n -p 80 --open 192.168.17.0-255 -oA full-tcp-192.168.17.0-255
[>] There are currently 2 nmap scans running on your system.
[>] Running: nmap -sS -v -n -p 80 --open 192.168.18.0-255 -oA full-tcp-192.168.18.0-255
[>] There are currently 3 nmap scans running on your system.
[>] Running: nmap -sS -v -n -p 80 --open 192.168.19.0-255 -oA full-tcp-192.168.19.0-255
[>] There are currently 4 nmap scans running on your system.
[>] Running: nmap -sS -v -n -p 80 --open 192.168.20.0-255 -oA full-tcp-192.168.20.0-255
[>] There are currently 5 nmap scans running on your system.
[!] too much scans already. waiting to clear

[...]
```

__Tips:__
- Use Ctrl+a " (with default `screen` shortcuts configuration) to navigate through the scans after re-attaching to the `screen` session.
- To stop all scans running the background, use the `killall screen` command.



License
================================
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
