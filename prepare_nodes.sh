#!/bin/bash

# TO BE RUN AS hduser

if [[ $# != 3 ]];then
  echo "Usage ./prepare_nodes.sh MASTER_IP existing_nodes new_nodes"
  exit 1
fi

source ~/.profile

MASTER_IP=$1
NODE_FILE=$2
NEW_NODE_FILE=$3

#-------------------------------------------------------------------------------
# Build new nodes
if [[ -e $NEW_NODE_FILE ]]; then

  echo "Please setup hduser and password less auth on all nodes"
  echo "ssh_setup.sh contains snippet that could help."
  echo "Press any key to continue."
  read

  touch ~/.vimrc
  while IFS='' read -r node_ip; do
    # prepare dirs
    scp hadoop.tar.gz hduser@$node_ip:~/
    scp hbase.tar.gz hduser@$node_ip:~/
    ssh -tt hduser@$node_ip <<EOF
sudo rm -rf /usr/local/hadoop
sudo tar -xvf hadoop.tar.gz -C /usr/local/
sudo chown -R hduser:hadoop /usr/local/hadoop/

sudo rm -rf /usr/local/hbase
sudo tar -xvf hbase.tar.gz -C /usr/local/
sudo chown -R hduser:hadoop /usr/local/hbase/

exit
EOF

    # set up env
    scp ~/.profile ~/.vimrc hduser@$node_ip:~/
    ssh -tt hduser@$node_ip <<EOF
sed -i.bak 's/export JAVA_HOME=\${JAVA_HOME}/export JAVA_HOME=\$(readlink -f \/usr\/bin\/java | sed "s:bin\/java::")/'  /usr/local/hadoop/etc/hadoop/hadoop-env.sh
exit
EOF

    ssh -tt hduser@$node_ip <<EOF
source ~/.profile
mkdir -pv /usr/local/hadoop/data/datanode
mkdir -pv $HADOOP_INSTALL/logs
exit
EOF
done < $NEW_NODE_FILE

# Merge node files
cat $NEW_NODE_FILE >> $NODE_FILE
rm $NEW_NODE_FILE

fi

#-------------------------------------------------------------------------------
# Update local config
echo "${MASTER_IP}" > $HADOOP_HOME/etc/hadoop/slaves
cat $NODE_FILE >> $HADOOP_HOME/etc/hadoop/slaves
cp $HADOOP_HOME/etc/hadoop/slaves $HBASE_HOME/conf/regionservers


#-------------------------------------------------------------------------------
# Update remote config
while IFS='' read -r node_ip; do
  # copy config
  scp -r $HADOOP_INSTALL/etc/hadoop  hduser@$node_ip:$HADOOP_INSTALL/etc/
  scp -r $HBASE_HOME/conf hduser@$node_ip:$HBASE_HOME/

  # Copy hosts config
  scp /etc/hosts hduser@$node_ip:~/
  ssh -tt hduser@$node_ip <<EOF
sudo mv ~/hosts /etc/hosts
exit
EOF
done < $NODE_FILE

#-------------------------------------------------------------------------------
# Format HDFS and Zookeepr (thus reset also HBase)
rm -rf $HADOOP_HOME/data/datanode/*
rm -rf $HADOOP_HOME/data/namenode/*
rm -rf /usr/local/zookeeper/*

# Reset remote
while IFS='' read -r node_ip; do
  ssh -tt hduser@$node_ip <<EOF
rm -rf $HADOOP_HOME/data/datanode/*
rm -rf $HADOOP_HOME/data/namenode/*
sudo mkdir -p /usr/local/zookeeper/
sudo chown hduser:hadoop /usr/local/zookeeper/
rm -rf /usr/local/zookeeper/*
exit
EOF
done < $NODE_FILE

yes | hdfs namenode -format
