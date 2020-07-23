# Setup JFrog Xray
Recommended way of deployment is thru Azure marketplace.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjfrog%2FJFrog-Cloud-Installers%2Farm-xray%2FAzureResourceManager%2FXray%2Fazuredeploy_xray_vmss.json" target="_blank">
<img src="https://aka.ms/deploytoazurebutton"/>
</a>

This template can help you setup the [JFrog Xray](https://jfrog.com/xray/) on Azure as a Custom Deployment.

## Prerequisites 
JFrog Xray is an addition to JFrog Artifactory. 
To be able to use it you need to have Artifactory instance deployed in Azure with Enterprise+ license, or Enterprise license with Xray addon.
Deployed Postgresql instance (if "existing DB" is selected as a parameter).

## Postgresql deployment
Xray could fail to connect to "out of the box" Azure Postgresql, [issue description](https://github.com/jfrog/charts/issues/422#issuecomment-516431036).
You can deploy Postgresql instance using this link:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjfrog%2FJFrog-Cloud-Installers%2Farm-xray%2FAzureResourceManager%2FPostgresql%2FazurePostgresDBDeploy.json" target="_blank">
<img src="https://aka.ms/deploytoazurebutton"/>
</a>

In the Databases field, use the object: 

```
  {
    "properties": [
      {
        "name": "xray",
        "charset": "UTF8",
        "collation": "English_United States.1252"
      }
    ]
  }
```
Before deploying Xray, please do following steps:
1. Use the admin role given by Azure that you initially connected with to PSDB (for example xray) - Remember the password of this role to connect when setting up with Xray.

2. Create a new role named xray@{hostname}, where {hostname} is a DB server name. 

3. Add xray@{hostname} membership to the base Azure user. In the client tab (PgAdmin for example) right click on properties of role "azure_pg_admin" and under Membership tab, add the relevant "xray@{hostname}", click on the checkbox on the tag, save.

4. Change ownership of Xray database. Right click On the name of the database and change owner to "xray@{hostname}"

After these steps are done, run Xray deployment. 

## Installation
1. Click "Deploy to Azure" button. If you haven't got an Azure subscription, it will guide you on how to signup for a free trial.

2. Enter a valid values to parameters. Make sure to use Artifactory Join key, which you can copy from Artifactory UI, Security -> Settings -> Connection details 

3. Click Review + Create, then click Create to start the deployment 

4. Once deployment is done, access Xray thru Artifactory UI, Security & Compliance menu




### Note: 
1. This template only supports Xray versions 3.2.x and above.
2. Input values for 'adminUsername' and 'adminPassword' parameters needs to follow azure VM access rules.

### Steps to upgrade JFrog Xray version

SSH to the Xray VM and CD to the /opt/ folder. Create an empty file upgrade.sh

``touch upgrade.sh``

Make the file executable:

```chmod +x upgrade.sh```

Open the file 

```vi upgrade.sh```

Paste the commands below (check the version of Xray you want to upgrade to):
```
cd /opt/
echo "### Stopping Xray service before upgrade ###"
systemctl stop xray.service
XRAY_VERSION=3.6.2
wget -O jfrog-xray-${XRAY_VERSION}-deb.tar.gz https://api.bintray.com/content/jfrog/jfrog-xray/xray-deb/${XRAY_VERSION}/jfrog-xray-${XRAY_VERSION}-deb.tar.gz?bt_package=jfrog-xray
tar -xvf jfrog-xray-${XRAY_VERSION}-deb.tar.gz
rm jfrog-xray-${XRAY_VERSION}-deb.tar.gz
cd jfrog-xray-${XRAY_VERSION}-deb
echo "### Run Xray installation script ###"
echo "y" | ./install.sh
echo "### Start Xray service ###"
systemctl start xray.service
```
Run the script

```./upgrade.sh```

The script will upgrade existing 3.x version of Xray to the given version. Check /var/opt/jfrog/xray/console.log to make sure that the service was properly started. Look for the message:
```All services started successfully in 10.743 seconds```
and check the application version in the log. 

