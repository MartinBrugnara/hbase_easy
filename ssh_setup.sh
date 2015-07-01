#!/bin/bash
tail -n+5 `basename "$0"` | more
exit

# TO BE RUN on developer machine
# Require sshpass
# Config
USER=
PASSWORD=
EXTRA_OPT=

NODES_FILE=
PRIVATE_IP_FILE= # aka nodes
PRIVATE_IP_START=

# ec2 EXAMPLE
#USER=ec2-user
#PASSWORD="ahahReallyNo"
#EXTRA_OPT="-i myCert.pem"
#PRIVATE_IP_START=10

HDUSER_PASSWORD=
#
while IFS='' read -r node_ip; do
    sshpass -p "$PASSWORD" -tt $EXTRA_OPT ec2-user@$node_ip <<EOF
sudo groupadd hadoop && sudo adduser -g hadoop -G wheel hduser
echo '%wheel  ALL=(ALL)       NOPASSWD: ALL' | (sudo EDITOR="tee -a" visudo)
echo "$HDUSER_PASSWORD" | sudo passwd hduser --stdin
sudo sed -i.bak 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo /etc/init.d/sshd restart
ip addr | grep "inet $PRIVATE_IP_START" | awk -F' ' '{print \$2}' | awk -F'/' '{print \$1}'
exit
EOF
done < $NODES_FILE | grep "^$PRIAVTE_IP_START" > PRIVATE_IP_FILE

# ------------------------------------------------------------------------------
# TO BE RUN on master as hduser

# do just once
ssh-keygen -t rsa -q
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# do for each new node
while IFS='' read -r node_ip; do
  # copy hduser keys
  scp -r ~/.ssh  hduser@$node_ip:~/

  # Disable password auth
  sshpass -p "$HDUSER_PASSWORD" -tt hduser@$node_ip <<EOF
sudo sed -i.bak 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo /etc/init.d/sshd restart
exit
EOF
done < $PRIVATE_IP_FILE
