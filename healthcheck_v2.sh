#!/bin/bash
# This script will do a quick check on CPU, Process, Disk Usage and Memory status.
# I got the idea from Yevhen Duma script.

echo "
####################################################################
Health Check Report (CPU,Process,Disk Usage, Memory)
####################################################################
"

#hostname command returns hostname
echo "Hostname : `hostname`"

#uname command with key -r returns Kernel version
echo "Kernel Version : `uname -r`"

#uptime command used to get uptime, and with sed command we cat process output to get only uptime.
echo -e "Uptime : `uptime | sed 's/.*up \([^,]*\), .*/\1/'`"

#who command is used to get last reboot time, awk for processing output
echo -e "Last Boot Time : `who -b | awk '{print $3,$4}'`"

echo "*********************************************************************"

echo "
*********************************************************************
Server Load - > Threshold < 1 Normal > 1 Caution , > 2 Unhealthy
*********************************************************************
"
echo -e "Load Average: `uptime | awk -F'load average:' '{print $2}' | cut -f1 -d,`"

echo -e "Health Status: `uptime | awk -F'load average:' '{print $2}' | cut -f1 -d, | awk '{if($1 > 2) print "Unhealthy";else if ($1 > 1) print "Caution"; else print "Normal"}'`"

echo -e "
******************************************************************
Process
******************************************************************
Top memory using processs/application
PID %MEM RSS COMMAND
`ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10`

Top CPU using process/application
`top b -n1 | head -17 | tail -11`
**********************************************************************
"
echo -e "
**********************************************************************
Disk Usage - > Threshold < 90 Normal > 90% Caution > 95 Unhealthy
**********************************************************************
"
#we get disk usage with df command. -P key used to have postfix like output (there was problems with network shares, etc and -P resolve this problems). We print output to temp file to work with info more than one.
df -Pkh | grep -v 'Filesystem' > /tmp/df.status


echo -e "Filesystem Health Status"
echo

# We check the disk usage status.
while read DISK
do
    USAGE=`echo $DISK | awk '{print $5}' | cut -f1 -d%`
    if [ $USAGE -ge 90 ]
    then
        STATUS='Unhealthy'
    else
        STATUS='Normal'
    fi
    LINE=`echo $DISK| awk '{print $6}'`
    echo -ne $LINE "\t\t" $STATUS
    echo
done < /tmp/df.status

echo
echo -e "Status"
echo

#Remove df.status file
rm /tmp/df.status

#here we get Total Memory, Used Memory, Free Memory, Used Swap and Free Swap values and save them to variables.
TOTALMEM=`free -m | head -2 | tail -1| awk '{print $2}'`
TOTALBC=`echo "scale=2;if($TOTALMEM<1024 && $TOTALMEM > 0) print 0;$TOTALMEM/1024"| bc -l`
USEDMEM=`free -m | head -2 | tail -1| awk '{print $3}'`
USEDBC=`echo "scale=2;if($USEDMEM<1024 && $USEDMEM > 0) print 0;$USEDMEM/1024"|bc -l`
FREEMEM=`free -m | head -2 | tail -1| awk '{print $4}'`
FREEBC=`echo "scale=2;if($FREEMEM<1024 && $FREEMEM > 0) print 0;$FREEMEM/1024"|bc -l`
TOTALSWAP=`free -m | tail -1| awk '{print $2}'`
TOTALSBC=`echo "scale=2;if($TOTALSWAP<1024 && $TOTALSWAP > 0) print 0;$TOTALSWAP/1024"| bc -l`
USEDSWAP=`free -m | tail -1| awk '{print $3}'`
USEDSBC=`echo "scale=2;if($USEDSWAP<1024 && $USEDSWAP > 0) print 0;$USEDSWAP/1024"|bc -l`
FREESWAP=`free -m |  tail -1| awk '{print $4}'`
FREESBC=`echo "scale=2;if($FREESWAP<1024 && $FREESWAP > 0) print 0;$FREESWAP/1024"|bc -l`

echo -e "
*********************************************************************
                     Memory
*********************************************************************
=> Physical Memory
Total\tUsed\tFree\t%Free
${TOTALBC}GB\t${USEDBC}GB \t${FREEBC}GB\t$(($FREEMEM * 100 / $TOTALMEM  ))%
=> Swap Memory
Total\tUsed\tFree\t%Free
${TOTALSBC}GB\t${USEDSBC}GB\t${FREESBC}GB\t$(($FREESWAP * 100 / $TOTALSWAP  ))%
*********************************************************************
                     Network
*********************************************************************

`ifconfig`


*********************************************************************
                     Hardware
*********************************************************************
`hplog -v`

*********************************************************************
                     Server log
*********************************************************************
`tail -25 /var/log/messages`

*********************************************************************
                     Etrust denails
*********************************************************************
`seaudit -a | grep ' D ' | tail -10`

*********************************************************************
                     SBR Status
*********************************************************************

`DTStat -n 3`
"
