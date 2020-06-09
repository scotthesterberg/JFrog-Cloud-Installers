#!/bin/bash
DB_URL=$(cat /var/lib/cloud/instance/user-data.txt | grep "^JDBC_STR" | sed "s/JDBC_STR=//")
DB_NAME=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_NAME=" | sed "s/DB_NAME=//")
DB_USER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_USER=" | sed "s/DB_ADMIN_USER=//")
DB_PASSWORD=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_PASSWD=" | sed "s/DB_ADMIN_PASSWD=//")
STORAGE_ACCT=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_ACT_NAME=" | sed "s/STO_ACT_NAME=//")
STORAGE_CONTAINER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_CTR_NAME=" | sed "s/STO_CTR_NAME=//")
STORAGE_ACCT_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_ACT_KEY=" | sed "s/STO_ACT_KEY=//")
ARTIFACTORY_VERSION=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_VERSION=" | sed "s/ARTIFACTORY_VERSION=//")
MASTER_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^MASTER_KEY=" | sed "s/MASTER_KEY=//")
IS_PRIMARY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^IS_PRIMARY=" | sed "s/IS_PRIMARY=//")
JFROG_URL=$(cat /var/lib/cloud/instance/user-data.txt | grep "^JFROG_URL=" | sed "s/JFROG_URL=//")

export DEBIAN_FRONTEND=noninteractive


# Create master.key on each node
mkdir -p /opt/jfrog/artifactory/var/etc/security/
cat <<EOF >/opt/jfrog/artifactory/var/etc/security/master.key
${MASTER_KEY}
EOF



# Node settings

# /var/opt/jfrog/xray/etc/system.yaml

HOSTNAME=$(hostname -i)
sed -i -e "s/#id: \"art1\"/id: \"${NODE_NAME}\"/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/#ip:/ip: ${HOSTNAME}/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/#primary: true/primary: ${IS_PRIMARY}/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/#haEnabled:/haEnabled:/" /var/opt/jfrog/xray/etc/system.yaml

# Set MS SQL configuration
cat <<EOF >>/var/opt/jfrog/artifactory/etc/system.yaml
    ## One of: mysql, oracle, mssql, postgresql, mariadb
    ## Default: Embedded derby
      type: postgresql
      driver: org.postgresql.Driver
      url: ${DB_URL}/${DB_NAME}?sslmode=disable
      username: ${DB_USER}
      password: ${DB_PASSWORD}
    jfrogUrl: <JFrog URL> # LB IP address? Internal IP?

EOF



systemctl start xray.service
echo "INFO: Xray HA installation completed."
