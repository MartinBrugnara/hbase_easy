#!/bin/bash

# Centos, REHL, Amazon Linux  & company

#REQUIREMENTS:
# - node files
# - yet correct host file (with all the records)

MASTER_IP=""
HADOOP_MASTER=$MASTER_IP
HBASE_MASTER=$MASTER_IP
ZK_QUORUM=""

HADOOP_VERSION=2.6.0
HBASE_VERSION=1.1.0.1

# Set up user and groups
sudo groupadd hadoop
sudo useradd -g hadoop -G wheel hduser
sudo usermod -a -G wheel hduser

# Use the new created user
sudo su - hduser

# setup ssh pub_key authentication
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# Install Hadoop & HDFS
if [[ $* != *--not-hbase* ]]; then

    # Download Hadoop
    curl -O https://dist.apache.org/repos/dist/release/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz.mds
    curl -O https://dist.apache.org/repos/dist/release/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz

    # Verify md5
    cat hadoop-${HADOOP_VERSION}.tar.gz.mds | grep MD5 | awk -F= '{print $2}' | awk '{ gsub (" ", "", $0); print}' > hadoop-${HADOOP_VERSION}.tar.gz.md5
    sed -i.bak -e 's/$/  hadoop-${HADOOP_VERSION}.tar.gz/' hadoop-${HADOOP_VERSION}.tar.gz.md5 && \
    rm hadoop-${HADOOP_VERSION}.tar.gz.md5.bak
    md5sum -c hadoop-${HADOOP_VERSION}.tar.gz.md5 || exit

    # Install Hadoop to /usr/local/ and add version agnostic symbolic link
    sudo tar -xvf hadoop-${HADOOP_VERSION}.tar.gz -C /usr/local/
    sudo ln -s /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop
    sudo chown -R hduser:hadoop /usr/local/hadoop-${HADOOP_VERSION}/

    mv hadoop-${HADOOP_VERSION}.tar.gz hadoop.tar.gz

    # Prepare helper
    cat <<EOF >> ~/.profile
export JAVA_HOME=\$(readlink -f /usr/bin/java | sed "s:bin/java::")
export HADOOP_INSTALL=/usr/local/hadoop
export HADOOP_HOME=\$HADOOP_INSTALL
export PATH=\$PATH:\$HADOOP_INSTALL/bin
export PATH=\$PATH:\$HADOOP_INSTALL/sbin
export HADOOP_MAPRED_HOME=\$HADOOP_INSTALL
export HADOOP_COMMON_HOME=\$HADOOP_INSTALL
export HADOOP_HDFS_HOME=\$HADOOP_INSTALL
export HADOOP_CONF_DIR=\${HADOOP_HOME}"/etc/hadoop"
export YARN_HOME=\$HADOOP_INSTALL

alias hfs="hdfs dfs"
EOF

    source ~/.profile

    # Generate "sane" config
    ./gen_hadoop_conf.sh $HADOOP_MASTER

    # Fix java path
    sed -i.bak 's@.*export JAVA_HOME=.*@export JAVA_HOME=\$(readlink -f /usr/bin/java | sed "s:bin/java::")@g'  $HADOOP_INSTALL/etc/hadoop/hadoop-env.sh

    # Create used directories
    mkdir -pv /usr/local/hadoop/data/namenode
    mkdir -pv /usr/local/hadoop/data/datanode
    mkdir -pv $HADOOP_INSTALL/logs

    # NOTE:
    # Slaves configuration will by performed by "prepare_node.sh" script
fi


# Install HBase
if [[ $* != *--not-hbase* ]]; then

    # Download HBase
    curl -O https://www.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz.mds
    curl -O https://www.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz

    # Verify md5
    cat hbase-${HBASE_VERSION}-bin.tar.gz.mds | grep MD5 | awk -F= '{print $2}' | awk '{ gsub (" ", "", $0); print}' > hbase-${HBASE_VERSION}-bin.tar.gz.md5
    TMP=$(cat hbase-${HBASE_VERSION}-bin.tar.gz.mds | grep -A1 MD5 | tail -n 1 | awk '{ gsub (" ", "", $0); print}')
    sed -i.bak -e "s/$/${TMP}  hbase-${HBASE_VERSION}-bin.tar.gz/" hbase-${HBASE_VERSION}-bin.tar.gz.md5 && \
    rm hbase-${HBASE_VERSION}-bin.tar.gz.md5.bak
    md5sum -c hbase-${HBASE_VERSION}-bin.tar.gz.md5 || exit


    # Install to /usr/local
    sudo tar -xvf hbase-${HBASE_VERSION}-bin.tar.gz -C /usr/local/
    sudo ln -s /usr/local/hbase-${HBASE_VERSION}/ /usr/local/hbase
    sudo chown -R hduser:hadoop /usr/local/hbase-${HBASE_VERSION}/

    mv hbase-${HBASE_VERSION}-bin.tar.gz hbase.tar.gz

    # Prepare helper
    cat <<EOF >> ~/.profile
export HBASE_HOME=/usr/local/hbase
export HBASE=\$HBASE_HOME/bin
export PATH=\$HBASE:\$PATH
EOF

    source ~/.profile

    # generate "sane" config
    ./gen_hbase_conf.sh $HADOOP_MASTER $HBASE_MASTER $ZK_QUORUM

    # Prepare directory
    sudo mkdir -p /usr/local/zookeeper
    sudo chown hduser:hadoop -R /usr/local/zookeeper

    # Fix java path
    sed -i.bak 's@.*export JAVA_HOME=.*@export JAVA_HOME=\$(readlink -f /usr/bin/java | sed "s:bin/java::")@g'  $HBASE_HOME/conf/hadoop-env.sh

    # NOTE:
    # Slaves configuration will by performed by "prepare_node.sh" script
fi

echo "Please set up password less (key based) ssh access to all nodes."
echo "   ssh_setup.sh script can help"
echo "And then complete the install with prepare_nodes.sh"
