#!/bin/sh
col=30
PORT=`cat PORT`
[ "$PORT" == "" ] && PORT=2222

iptables -A INPUT -p tcp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport "$PORT" -m conntrack --ctstate ESTABLISHED -j ACCEPT

# enable wireless if it is currently off
WIFI_WAS_OFF=0
if [ 0 -eq `lipc-get-prop com.lab126.cmd wirelessEnable` ]; then
	eips $col 3 "WiFi is off, turning it on now"
	lipc-set-prop com.lab126.cmd wirelessEnable 1
	WIFI_WAS_OFF=1
fi

# refresh IP display in the background
while :; do
    eips $((col-5)) 0 "ssh root@`ifconfig wlan0 | grep 'inet addr' | awk -F '[ :]' '{print $13}'` -p$PORT"
    sleep 3
    if [ 0 -eq `lipc-get-prop com.lab126.cmd wirelessEnable` ]; then
    	lipc-send-event com.lab126.hal powerButtonPressed
    	break
    fi
done > /dev/null &


./dropbear -E -R -p"$PORT" -P KOSSH.pid -n
#ref: koreader/plugins/SSH.koplugin/main.lua

# waiting for powerButtonPressed
PSS_WAS_OFF=0
if [ 0 -eq `lipc-get-prop com.lab126.powerd preventScreenSaver` ]; then
	lipc-set-prop -i com.lab126.powerd preventScreenSaver 1
	PSS_WAS_OFF=1
fi
lipc-wait-event  com.lab126.hal powerButtonPressed | read event #it's blocking
# Restore PSS status
if [ 1 -eq $PSS_WAS_OFF ]; then
	lipc-set-prop -i com.lab126.powerd preventScreenSaver 0
fi

kill $(jobs -p)
eips $col 3 "ssh server is turned off      "

# Restore WiFi status
if [ 1 -eq $WIFI_WAS_OFF ] && [ 1 -eq `lipc-get-prop com.lab126.cmd wirelessEnable` ]; then
	lipc-set-prop com.lab126.cmd wirelessEnable 0
	sleep 0.5
	eips $col 3 "Turning off WiFi              "
fi

# Clear screen
sleep 1
eips $((col-5)) 0 "                               "
eips $col 3 "                              "

# stop tasks
cat KOSSH.pid | xargs kill
iptables -D INPUT -p tcp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -D OUTPUT -p tcp --sport "$PORT" -m conntrack --ctstate ESTABLISHED -j ACCEPT
killall dropbear