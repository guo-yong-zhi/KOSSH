PORT=2222
cat KOSSH.pid | xargs kill
iptables -D INPUT -p tcp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -D OUTPUT -p tcp --sport "$PORT" -m conntrack --ctstate ESTABLISHED -j ACCEPT
killall dropbear