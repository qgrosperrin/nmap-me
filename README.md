Description
===========
This is a basic BASH script designed to automated and help manage nmap scans. The script provides an option to separate the target range into smaller subnets to help reduce overhead when scanning big network ranges. Each individual nmap scan receives its own 'screen' window within a common 'screen' session, further allowing the scans to be segregated and resilient to shell disruption (e.g. via SSH). Use Ctrl+a ", via standard screen shortcuts config, to navigate through the scans after re-attaching to the screen session. 

Depending on the size of each resulting subnet, specified in the CLI using the '-s' argument, the script could create a huge number of nmap processes, potentially affecting the stability and availability of the target. As a result, the '-m' option can be leveraged to specify the maximum number of simultaneous nmap scans that should be running on the system. Upon reaching the maximum number specified (unlimited if un-specified), the script will wait for nmap scans running to finish before launch a new scan.
__Note__: at the moment, the script does not make any difference between your nmap scans launched by the tool, and other nmap scans launched in the background by other users. This is a known bug. If additional scans are running on the system, it may therefore limit the tool in his ability to launch new scans.


Usage
=====
This tool requires __nmap__ and __sipcalc__ (used by the '-s' option)  to be installed on the system.

```
 NmapMe (v 0.1) 
 USAGE: ./nmap_me.sh -s [SIZE] -t [TARGET] -m [NB_SCANS]

 REQUIRED                                           
         -t  Target IP range.                
                                           
 OPTIONAL                                           
         -s  Divide scans into chunk of maximum size specified. 
         -m  Maximum number of simultaneous scans 
```


License
================================
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
