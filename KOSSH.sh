PORT=2222

iptables -A INPUT -p tcp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport "$PORT" -m conntrack --ctstate ESTABLISHED -j ACCEPT

./dropbear -E -R -p"$PORT" -P KOSSH.pid -n

#ref: koreader/plugins/SSH.koplugin/main.lua