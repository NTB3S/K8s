kubeadm reset -f
sudo iptables-restore < ~/iptables-rules-mod
## check
## save the changes
sudo netfilter-persistent save
sudo systemctl restart iptables

