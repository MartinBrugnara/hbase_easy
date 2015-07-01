#!/bin/bash

# TO BE EXECUTED AS hduser !
# arguments: HADOOP_MASTER

source ~/.profile

if [[ $# != 1 ]]; then
    echo "Usage: ./gen_hadoop_conf.sh HADOOP_MASTER"
    exit 1
fi

HADOOP_MASTER=$1

# Base Hadoop config
cat <<EOF > $HADOOP_INSTALL/etc/hadoop/hdfs-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:///usr/local/hadoop/data/datanode</value>
        <description>DataNode directory</description>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:///usr/local/hadoop/data/namenode</value>
        <description>NameNode directory for namespace and transaction logs storage.</description>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
        <description>lte then num of nodes</description>
    </property>
    <property>
        <name>dfs.permissions</name>
        <value>false</value>
    </property>
    <property>
        <name>dfs.datanode.use.datanode.hostname</name>
        <value>false</value>
    </property>
    <property>
        <name>dfs.namenode.datanode.registration.ip-hostname-check</name>
        <value>false</value>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>$HADOOP_MASTER:50070</value>
        <description>Your NameNode hostname for http access.</description>
    </property>

    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>$HADOOP_MASTER:50090</value>
        <description>Your Secondary NameNode hostname for http access.</description>
    </property>
</configuration>
EOF

cat <<EOF > $HADOOP_INSTALL/etc/hadoop/core-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://$HADOOP_MASTER/</value>
        <description>NameNode URI</description>
    </property>
</configuration>
EOF

cat <<EOF > $HADOOP_INSTALL/etc/hadoop/yarn-site.xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address</name>
        <value>$HADOOP_MASTER:8025</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address</name>
        <value>$HADOOP_MASTER:8030</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>$HADOOP_MASTER:8050</value>
    </property>
</configuration>
EOF
