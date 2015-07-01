#!/bin/bash

# Install Oracle Java 8 on a list of nodes via ssh
# usage cat nodes | OracleJava8.sh
if [[ $# != 1 ]]; then
    echo "Usage cat nodes | xargs -L1  ./OracleJava8.sh"
    echo "or: ./OracleJava8.sh 'ip'"
    exit 1
fi

node_ip=$1

ssh -tt hduser@$node_ip <<EOF
curl -O http://javadl.sun.com/webapps/download/AutoDL?BundleId=106239
mv AutoDL?BundleId=106239 jre-8u45-linux-x64.rpm
sudo rpm -i jre-8u45-linux-x64.rpm && rm jre-8u45-linux-x64.rpm
sudo /usr/sbin/alternatives --install /usr/bin/java java /usr/java/jre1.8.0_45/bin/java 20000
echo "2" | sudo /usr/sbin/alternatives --config java
exit
EOF
