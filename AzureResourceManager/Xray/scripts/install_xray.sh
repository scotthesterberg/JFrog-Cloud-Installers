#!/bin/bash
DB_URL=$(cat /var/lib/cloud/instance/user-data.txt | grep "^JDBC_STR" | sed "s/JDBC_STR=//")
DB_NAME=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_NAME=" | sed "s/DB_NAME=//")
DB_USER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_USER=" | sed "s/DB_ADMIN_USER=//")
DB_PASSWORD=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_PASSWD=" | sed "s/DB_ADMIN_PASSWD=//")
DB_SERVER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_SERVER=" | sed "s/DB_SERVER=//")
STORAGE_ACCT=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_ACT_NAME=" | sed "s/STO_ACT_NAME=//")
STORAGE_CONTAINER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_CTR_NAME=" | sed "s/STO_CTR_NAME=//")
STORAGE_ACCT_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_ACT_KEY=" | sed "s/STO_ACT_KEY=//")
ARTIFACTORY_VERSION=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_VERSION=" | sed "s/ARTIFACTORY_VERSION=//")
MASTER_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^MASTER_KEY=" | sed "s/MASTER_KEY=//")
JOIN_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^JOIN_KEY=" | sed "s/JOIN_KEY=//")
IS_PRIMARY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^IS_PRIMARY=" | sed "s/IS_PRIMARY=//")
ARTIFACTORY_URL=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_URL=" | sed "s/ARTIFACTORY_URL=//")

export DEBIAN_FRONTEND=noninteractive


# Create master.key on each node
sudo mkdir -p /opt/jfrog/xray/var/etc/security/
cat <<EOF >/opt/jfrog/xray/var/etc/security/master.key
${MASTER_KEY}
EOF

HOSTNAME=$(hostname -i)
TIMESTAMP=$(echo '('`date +"%s.%N"`' * 1000000)/1' | bc)
sed -i -e "s/#id: \"<For example: xray1>\"/id: \"xray-${TIMESTAMP}\"/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/#ip:/ip: ${HOSTNAME}/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/#jfrogUrl:/jfrogUrl: \"http:\/\/${ARTIFACTORY_URL}\"/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/#joinKey:..*/joinKey: ${JOIN_KEY}/" /var/opt/jfrog/xray/etc/system.yaml
# DB configuration
sed -i -e "s/#type: postgresql/type: \"postgresql\"/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/#driver: org.postgresql.Driver/driver: \"org.postgresql.Driver\"/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/#url: postgres:..*/url: \"postgres:\/\/${DB_SERVER}.postgres.database.azure.com:5432\/${DB_NAME}?sslmode=disable\"/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/#username: xray/username: \"${DB_USER}\"/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/#password: xray/password: \"${DB_PASSWORD}\"/" /var/opt/jfrog/xray/etc/system.yaml

chown xray:xray -R /opt/jfrog/xray/var/etc/security/* && chown xray:xray -R /opt/jfrog/xray/var/etc/security/

systemctl start xray.service
echo "INFO: Xray HA installation completed."
