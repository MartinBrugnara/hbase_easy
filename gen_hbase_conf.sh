#!/bin/bash

# TO BE EXECUTED AS hduser !
# arguments: HADOOP_MASTER HBASE_MASTER ZOOKEEPER_QUORUM

if [[ $# != 3 ]]; then
    echo "Usage: ./gen_hbase_conf.sh HADOOP_MASTER HBASE_MASTER ZK_QUORUM"
    exit 1
fi

HADOOP_MASTER=$1
HBASE_MASTER=$2
ZK_QUORUM=$3

source ~/.profile

cat <<EOF > $HBASE_HOME/conf/hbase-site.xml
<configuration>
    <property>
        <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>
    <property>
        <name>hbase.rootdir</name>
        <value>hdfs://$HADOOP_MASTER:8020/hbase</value>
    </property>
    <property>
        <name>hbase.zookeeper.quorum</name>
        <value>$ZK_QUORUM</value>
    </property>
    <property>
        <name>hbase.zookeeper.property.dataDir</name>
        <value>/usr/local/zookeeper</value>
    </property>
    <property>
        <name>hbase.master</name>
        <value>$HBASE_MASTER:60000</value>
        <description>The host and port that the HBase master runs at.</description>
    </property>
    <property>
        <name>hbase.master.port</name>
        <value>16000</value>
    </property>
    <property>
        <name>hbase.master.info.port</name>
        <value>16010</value>
        <description>web ui port</description>
    </property>
    <property>
        <name>hbase.regionserver.port</name>
        <value>16099</value>
    </property>
    <property>
        <name>hbase.regionserver.info.port</name>
        <value>16030</value>
    </property>

<!-- http://hbase-perf-optimization.blogspot.it/2013/03/hbase-configuration-optimization.html -->
    <property>
        <name>hbase.regionserver.lease.period</name>
        <value>1200000</value>
    </property>
    <property>
        <name>hbase.rpc.timeout</name>
        <value>1200000</value>
    </property>
    <property>
        <name>zookeeper.session.timeout</name>
        <value>20000</value>
    </property>
    <property>
        <name>hbase.regionserver.handler.count</name>
        <value>50</value>
    </property>
    <property>
        <name>hbase.zookeeper.property.maxClientCnxns</name>
        <value>1000</value>
    </property>
    <property>
        <name>hbase.client.scanner.caching</name>
        <value>100</value>
    </property>
    <property>
        <name>hbase.hregion.max.filesize</name>
        <value>10737418240</value>
    </property>
    <property>
        <name>hbase.hregion.majorcompaction</name>
        <value>0</value>
    </property>
    <property>
        <name>hbase.hregion.memstore.flush.size</name>
        <value>134217728</value>
    </property>
    <property>
        <name>hbase.hregion.memstore.block.multiplier</name>
        <value>4</value>
    </property>
    <property>
        <name>hbase.hstore.blockingStoreFiles</name>
        <value>30</value>
    </property>
</configuration>
EOF
