#!/bin/sh

# Version
version='trusty' # `lsb_release -c -s`

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

# TODO: Using this evn though outdated because there seems to be a bug in the alternative (see below).
wget https://archive.cloudera.com/cdh5/one-click-install/trusty/amd64/cdh5-repository_1.0_all.deb
sudo dpkg -i cdh5-repository_1.0_all.deb
sudo chmod 644 /etc/apt/trusted.gpg.d/cloudera-cdh5.gpg # Hack

# TODO: Debug: this results in 'SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder"' errors using HDFS...
#sudo add-apt-repository "deb [arch=amd64] https://archive.cloudera.com/cdh5/ubuntu/xenial/amd64/cdh xenial-cdh5.11.1 contrib"

#wget -qO - https://archive.cloudera.com/cdh5/ubuntu/precise/amd64/cdh/archive.key | sudo apt-key add -
wget -qO - https://archive.cloudera.com/cdh5/ubuntu/$version/amd64/cdh/archive.key | sudo apt-key add -

sudo apt-get update

# "pseudo-distributed" Hadoop deployment.
# In this mode, each of the hadoop components runs as a separate Java process,
# but all on the same machine.
sudo apt-get install -y hadoop-client

# Warning: this installs spark 1.6.0, not 2.1.1
sudo apt-get install -y spark-core spark-python
