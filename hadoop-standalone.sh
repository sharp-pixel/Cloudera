#!/bin/bash

# Version
version=`lsb_release -c -s`

# Written on 06/03/2017 by Cedric Pelvet
# Tested on Ubuntu 14.04.5 (trusty)
# Work-in-progress on Ubuntu 16.04.2 (xenial)

sudo sysctl vm.swappiness=10
sudo apt-get install -y ssh python-software-properties software-properties-common apt-transport-https

cat /dev/zero | ssh-keygen -t rsa -P ""

echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-add-repository -y ppa:webupd8team/java
sudo apt-get update
sudo apt-get install -y oracle-java8-installer

# TODO: Using this even though outdated because there seems to be a bug in the alternative (see below).
case "$version" in
"trusty")
	wget https://archive.cloudera.com/cdh5/one-click-install/trusty/amd64/cdh5-repository_1.0_all.deb
	sudo dpkg -i cdh5-repository_1.0_all.deb
	sudo chmod 644 /etc/apt/trusted.gpg.d/cloudera-cdh5.gpg # Hack
	;;
"xenial")
	# ALTERNATIVE method
	# TODO: Debug: this results in 'SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder"' errors using HDFS...
	#sudo add-apt-repository "deb [arch=amd64] https://archive.cloudera.com/cdh5/ubuntu/xenial/amd64/cdh xenial-cdh5.12 contrib"
	wget -qO - https://archive.cloudera.com/cdh5/ubuntu/$version/amd64/cdh/archive.key | sudo apt-key add -
	;;
*)
	echo "Unknown ubuntu version: $version"
	;;
esac

sudo apt-get update

# "pseudo-distributed" Hadoop deployment.
# In this mode, each of the hadoop components runs as a separate Java process,
# but all on the same machine.
sudo apt-get install -y hadoop-conf-pseudo

# Format the NameNode
sudo -u hdfs hdfs namenode -format

# Start the Hadoop services in the pseudo-distributed cluster
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x start ; done

# Create a sub-directory structure in HDFS
sudo /usr/lib/hadoop/libexec/init-hdfs.sh

# Start the YARN daemons
sudo service hadoop-yarn-resourcemanager start
sudo service hadoop-yarn-nodemanager start 
sudo service hadoop-mapreduce-historyserver start

sudo -u hdfs hadoop fs -mkdir /user/$USER
sudo -u hdfs hadoop fs -chown $USER /user/$USER

wget -qO - http://packages.confluent.io/deb/3.2/archive.key | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] http://packages.confluent.io/deb/3.2 stable main"
sudo apt-get update
sudo apt-get install -y confluent-platform-oss-2.11

# Warning: this installs spark 1.6.0, not 2.1.1
sudo apt-get install -y spark-core spark-master spark-worker spark-history-server spark-python

# Kudu
# NOTE: Kudu requires a CPU with SSE4.2 instructions support
# Check for SSE4.2, required for Kudu
grep "sse4_2" /proc/cpuinfo > /dev/null
if [ $? -eq 0 ]; then
	sudo wget http://archive.cloudera.com/kudu/ubuntu/$version/amd64/kudu/cloudera.list -O /etc/apt/sources.list.d/cloudera.list
	sudo apt-get update
	sudo apt-get install -y kudu kudu-master kudu-tserver libkuduclient0 libkuduclient-dev
	sudo update-rc.d kudu-master defaults
	sudo update-rc.d kudu-tserver defaults
else
	echo "Kudu unsupported on this system due to SSE 4.2 missing"
fi

# Install Oozie and Hue
#sudo apt-get install -y oozie
#sudo apt-get install -y hue
