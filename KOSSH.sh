PORT=`cat PORT`
[ "$PORT" == "" ] && PORT=2222

iptables -A INPUT -p tcp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport "$PORT" -m conntrack --ctstate ESTABLISHED -j ACCEPT

# enable wireless if it is currently off
WIFI_IS_OFF=0
if [ 0 -eq `lipc-get-prop com.lab126.cmd wirelessEnable` ]; then
	eips 30 3 "WiFi is off, turning it on now"
	lipc-set-prop com.lab126.cmd wirelessEnable 1
	WIFI_IS_OFF=1
fi

# refresh IP display in the background
while :; do
    eips 25 0 "ssh root@`ifconfig wlan0 | grep 'inet addr' | awk -F '[ :]' '{print $13}'` -p$PORT"
    sleep 3
done > /dev/null &


./dropbear -E -R -p"$PORT" -P KOSSH.pid -n
#ref: koreader/plugins/SSH.koplugin/main.lua

# waiting for powerButtonPressed
PSS_IS_OFF=0
if [ 0 -eq `lipc-get-prop com.lab126.powerd preventScreenSaver` ]; then
	lipc-set-prop -i com.lab126.powerd preventScreenSaver 1
	PSS_IS_OFF=1
fi
lipc-wait-event  com.lab126.hal powerButtonPressed | read event #it's blocking
# Restore PSS status
if [ 1 -eq $PSS_IS_OFF ]; then
	lipc-set-prop -i com.lab126.powerd preventScreenSaver 0
fi

kill $(jobs -p)
eips 30 3 "ssh server is turned off      "

# Restore WiFi status
if [ 1 -eq $WIFI_IS_OFF ]; then
	lipc-set-prop com.lab126.cmd wirelessEnable 0
	sleep 0.5
	eips 30 3 "Turning off WiFi              "
fi

# Clear screen
sleep 1
eips 25 0 "                               "
eips 30 3 "                              "

# stop ssh
cat KOSSH.pid | xargs kill
iptables -D INPUT -p tcp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -D OUTPUT -p tcp --sport "$PORT" -m conntrack --ctstate ESTABLISHED -j ACCEPT
killall dropbear