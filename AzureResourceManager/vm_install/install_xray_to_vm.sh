#!/bin/bash

# Upgrade version for every release
XRAY_VERSION=3.4.0

export DEBIAN_FRONTEND=noninteractive

# install the wget and curl
apt-get update -y
apt-get -y install wget curl >> /tmp/install-curl.log 2>&1

# Download X-ray
cd /opt/
wget -O jfrog-xray-${XRAY_VERSION}-deb.tar.gz 'https://bintray.com/jfrog/jfrog-xray/download_file?agree=true&artifactPath=/jfrog/jfrog-xray/xray-deb/'${XRAY_VERSION}'/jfrog-xray-'${XRAY_VERSION}'-deb.tar.gz&callback_id=&product=org.grails.taglib.NamespacedTagDispatcher' \
>> /tmp/download-xray.log 2>&1
tar -xvf jfrog-xray-${XRAY_VERSION}-deb.tar.gz
cd jfrog-xray-${XRAY_VERSION}-deb

# Install libwxbase3.0-0v5
sudo apt-get install libwxgtk3.0-0v5 -y >> /tmp/install-libwxbase3.log 2>&1

# Install db-utils
sudo apt-get install -y ./third-party/misc/db5.3-util_5.3.28-3ubuntu3_amd64.deb >> /tmp/install-db5.3-util_5.3.28-3ubuntu3_amd64.log 2>&1
sudo apt-get install -y ./third-party/misc/db-util_1_3a5.3.21exp1ubuntu1_all.deb >> /tmp/install-db-util_1_3a5.3.21exp1ubuntu1_all.log 2>&1

# Install RabbitMQ dependencies
sudo apt-get install -y ./third-party/rabbitmq/socat_1.7.3.1-2+deb9u1_amd64.deb >> /tmp/install-rabbitmq-socat.log 2>&1
sudo apt-get install -y ./third-party/rabbitmq/esl-erlang_21.2.1-1~ubuntu~bionic_amd64.deb >> /tmp/install-rabbitmq-esl.log 2>&1 # no dependency

# Install Xray as a root user
sudo apt-get install -y ./xray/xray.deb >> /tmp/install-xray.log 2>&1

# Remove Xray service from boot up run
systemctl disable xray.service
