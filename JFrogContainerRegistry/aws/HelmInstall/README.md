# JFrog Container Registry Helm Chart for AWS

[JFrog Container Registry](https://www.jfrog.com/confluence/display/JCR/Overview) is a free Artifactory edition with Docker and Helm repositories support.

## Prerequisites Details

* EKS cluster
* Helm
* (Optional) A preinstalled Database
* (Optional) An S3 bucket

## Chart Details
This chart will do the following:

* Deploy JFrog Container Registry
* (Optionally) Connect to an external Database
* (Optionally) Connect to an S3 butcket

## Installing the Chart

### Add JFrog Helm repository
Before installing JFrog helm charts, you need to add the [JFrog helm repository](https://charts.jfrog.io/) to your helm client
```bash
helm repo add jfrog https://charts.jfrog.io
```

### To simply get up and running without an external database or S3

1. Download the all-in-one.yaml value file: `wget https://raw.githubusercontent.com/jfrog/JFrog-Cloud-Installers/aws-jcr-6.17.0/JFrogContainerRegistry/aws/HelmInstall/all-in-one.yaml`
2. Run the helm installation with the all-in-one.yaml file: `helm install --name jfrog-container-registry jfrog/artifactory-jcr -f all-in-one.yaml`
3. After the JFrog Container Registry pod has started (it may take a couple of minutes), get the first-time password located at '/var/opt/jfrog/artifactory/generated-pass.txt': `kubectl exec -it jfrog-container-registry-artifactory-0 cat /var/opt/jfrog/artifactory/generated-pass.txt`
4. Follow the output of the `helm install` command to get the service address

### Install Chart with external PostgreSQL DB
To install the chart with the release name `jfrog-container-registry`:
```bash
helm install 
  --name jfrog-container-registry \
  --set artifactory.artifactory.image.repository=117940112483.dkr.ecr.us-east-1.amazonaws.com/3701884c-2c08-41f3-b4df-84743c6a9f58/198bdff5-aed9-4519-acef-83d6485135d4/partnership-public-images.jfrog.io/aws/artifactory-jcr \
  --set artifactory.artifactory.image.version=7.5.5-latest \
  --set artifactory.postgresql.enabled=false \
  --set artifactory.database.type=postgresql \
  --set artifactory.database.url='jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}' \
  --set artifactory.database.user=${DB_USER} \
  --set artifactory.database.password=${DB_PASSWORD} \
  jfrog/artifactory-jcr
```
**NOTE:** You must set `artifactory.postgresql.enabled=false` in order for the chart to use the `database.*` parameters. Without it, they will be ignored!


### Install Chart with external PostgreSQL DB
To install the chart with the release name `jfrog-container-registry`:
```bash
helm install 
  --name jfrog-container-registry \
  --set artifactory.artifactory.image.repository=117940112483.dkr.ecr.us-east-1.amazonaws.com/3701884c-2c08-41f3-b4df-84743c6a9f58/198bdff5-aed9-4519-acef-83d6485135d4/partnership-public-images.jfrog.io/aws/artifactory-jcr \
  --set artifactory.artifactory.image.version=7.5.5-latest \
  --set artifactory.postgresql.enabled=false \
  --set artifactory.database.type=postgresql \
  --set artifactory.database.url='jdbc:postgresql://${DB_HOST}:${DB_PORT}/my-artifactory-db' \
  --set artifactory.database.user=${DB_USER} \
  --set artifactory.database.password=${DB_PASSWORD} \
  jfrog/artifactory-jcr
```
**NOTE:** You must set `artifactory.postgresql.enabled=false` in order for the chart to use the `database.*` parameters. Without it, they will be ignored!

#### AWS S3
**NOTE** Keep in mind that when using the `aws-s3` persistence type, you will not be able to provide an IAM on the pod level. 
In order to grant permissions to Artifactory using an IAM role, you will have to attach the said IAM role to the machine(s) on which Artifactory is running.
This is due to the fact that the `aws-s3` template uses the `JetS3t` library to interact with AWS. If you want to grant an IAM role at the pod level, see the `AWS S3 Vs` section.

To use an AWS S3 bucket as the cluster's filestore. See [S3 Binary Provider](https://www.jfrog.com/confluence/display/RTF/Configuring+the+Filestore#ConfiguringtheFilestore-S3BinaryProvider)
- Pass AWS S3 parameters to `helm install` and `helm upgrade`
```bash
...
# With explicit credentials:
--set artifactory.persistence.type=aws-s3 \
--set artifactory.persistence.awsS3.endpoint=${AWS_S3_ENDPOINT} \
--set artifactory.persistence.awsS3.region=${AWS_REGION} \
--set artifactory.persistence.awsS3.identity=${AWS_ACCESS_KEY_ID} \
--set artifactory.persistence.awsS3.credential=${AWS_SECRET_ACCESS_KEY} \
...

...
# With using existing IAM role
--set artifactory.persistence.type=aws-s3 \
--set artifactory.persistence.awsS3.endpoint=${AWS_S3_ENDPOINT} \
--set artifactory.persistence.awsS3.region=${AWS_REGION} \
--set artifactory.persistence.awsS3.roleName=${AWS_ROLE_NAME} \
...
```
**NOTE:** Make sure S3 `endpoint` and `region` match. See [AWS documentation on endpoint](https://docs.aws.amazon.com/general/latest/gr/rande.html)

#### AWS S3 V3
To use an AWS S3 bucket as the cluster's filestore and access it with the official AWS SDK, See [S3 Official SDK Binary Provider](https://www.jfrog.com/confluence/display/RTF/Configuring+the+Filestore#ConfiguringtheFilestore-AmazonS3OfficialSDKTemplate). 
This filestore template uses the official AWS SDK, unlike th`aws-s3` implementation that uses the `JetS3t` library.
Use this template if you want to attach an IAM role to the Artifactory pod directly (as opposed to attaching it to the machine/s that Artifactory will run on).

**NOTE** This will have to be combined with a k8s mechanism for attaching IAM roles to pods, like [kube2iam](https://github.com/helm/charts/tree/master/stable/kube2iam) or anything similar.
 
- Pass AWS S3 V3 parameters and the annotation pointing to the IAM role (when using an IAM role. this is kube2iam specific and may vary depending on the implementation) to `helm install` and `helm upgrade`

```bash
# With explicit credentials:
--set artifactory.persistence.type=aws-s3-v3 \
--set artifactory.persistence.awsS3V3.region=${AWS_REGION} \
--set artifactory.persistence.awsS3V3.bucketName=${AWS_S3_BUCKET_NAME} \
--set artifactory.persistence.awsS3V3.identity=${AWS_ACCESS_KEY_ID} \
--set artifactory.persistence.awsS3V3.credential=${AWS_SECRET_ACCESS_KEY} \
...
```

```bash
# With using existing IAM role
--set artifactory.persistence.type=aws-s3-v3 \
--set artifactory.persistence.awsS3V3.region=${AWS_REGION} \
--set artifactory.persistence.awsS3V3.bucketName=${AWS_S3_BUCKET_NAME} \
--set artifactory.annotations.'iam\.amazonaws\.com/role'=${AWS_IAM_ROLE_ARN}
...
```

### Install Chart with external Other DB
There are cases where you will want to use a different database and not the enclosed **PostgreSQL**.
See more details on [configuring the database](https://www.jfrog.com/confluence/display/RTF/Configuring+the+Database)
> The official Artifactory Docker images include the PostgreSQL database driver.
> For other database types, you will have to add the relevant database driver to Artifactory's tomcat/lib




To install the chart with the release name `jfrog-container-registry`:
```bash
helm install 
  --name jfrog-container-registry \
  --set artifactory.artifactory.image.repository=117940112483.dkr.ecr.us-east-1.amazonaws.com/3701884c-2c08-41f3-b4df-84743c6a9f58/198bdff5-aed9-4519-acef-83d6485135d4/partnership-public-images.jfrog.io/aws/artifactory-jcr \
  --set artifactory.artifactory.image.version=7.5.5-latest \
  --set artifactory.postgresql.enabled=false \
  --set artifactory.artifactory.preStartCommand="wget -O /opt/jfrog/artifactory/tomcat/lib/mysql-connector-java-5.1.41.jar https://jcenter.bintray.com/mysql/mysql-connector-java/5.1.41/mysql-connector-java-5.1.41.jar" \
  --set artifactory.database.type=mysql \
  --set artifactory.database.host=${DB_HOST} \
  --set artifactory.database.port=${DB_PORT} \
  --set artifactory.database.user=${DB_USER} \
  --set artifactory.database.password=${DB_PASSWORD} \
  jfrog/artifactory-jcr
```
**NOTE:** You must set `postgresql.enabled=false` in order for the chart to use the `database.*` parameters. Without it, they will be ignored!


### Accessing JFrog Container Registry
**NOTE:** If using artifactory or nginx service type `LoadBalancer`, it might take a few minutes for JFrog Container Registry's public IP to become available.

### Updating JFrog Container Registry
Once you have a new chart version, you can upgrade your deployment with
```bash
helm upgrade jfrog-container-registry jfrog/artifactory-jcr
```

### Deleting JFrog Container Registry
```bash
helm delete --purge jfrog-container-registry
```
This will delete your JFrog Container Registry deployment.<br>
**NOTE:** You might have left behind persistent volumes. You should explicitly delete them with
```bash
kubectl delete pvc ...
kubectl delete pv ...
```

## Database
The JFrog Container Registry chart comes with PostgreSQL deployed by default.<br>
For details on the PostgreSQL configuration or customising the database, Look at the options described in the [Artifactory helm chart](https://github.com/jfrog/charts/tree/master/stable/artifactory). 

## Configuration
The following table lists the **basic** configurable parameters of the JFrog Container Registry chart and their default values.

**NOTE:** All supported parameters are documented in the main [artifactory helm chart](https://github.com/jfrog/charts/tree/master/stable/artifactory).

|         Parameter                              |           Description             |                         Default                   |
|------------------------------------------------|-----------------------------------|---------------------------------------------------|
| `artifactory.artifactory.image.repository`     | Container image                   | `docker.bintray.io/jfrog/artifactory-jcr`         |
| `artifactory.artifactory.image.version`        | Container tag                     | `.Chart.AppVersion`                               |
| `artifactory.artifactory.resources`            | Artifactory container resources   | `{}`                                              |
| `artifactory.artifactory.javaOpts`             | Artifactory Java options          | `{}`                                              |
| `artifactory.nginx.enabled`                    | Deploy nginx server               | `true`                                            |
| `artifactory.nginx.service.type`               | Nginx service type                | `LoadBalancer`                                    |
| `artifactory.nginx.tlsSecretName`              | TLS secret for Nginx pod          | ``                                                |
| `artifactory.ingress.enabled`                  | Enable Ingress (should come with `artifactory.nginx.enabled=false`) | `false`         |
| `artifactory.ingress.tls`                      | Ingress TLS configuration (YAML)  | `[]`                                              |
| `artifactory.postgresql.enabled`               | Use the Artifactory PostgreSQL sub chart       | `true`                               |
| `artifactory.database`                         | Custom database configuration (if not using bundled PostgreSQL sub-chart) |           |
| `postgresql.enabled`                           | Enable the Artifactory PostgreSQL sub chart    | `true`                               |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

### Ingress and TLS
To get Helm to create an ingress object with a hostname, add these two lines to your Helm command:
```bash
helm install --name artifactory \
  --set artifactory.artifactory.image.repository=117940112483.dkr.ecr.us-east-1.amazonaws.com/3701884c-2c08-41f3-b4df-84743c6a9f58/198bdff5-aed9-4519-acef-83d6485135d4/partnership-public-images.jfrog.io/aws/artifactory-jcr \
  --set artifactory.artifactory.image.version=7.5.5-latest \
  --set artifactory.nginx.enabled=false \
  --set artifactory.ingress.enabled=true \
  --set artifactory.ingress.hosts[0]="artifactory.company.com" \
  --set artifactory.artifactory.service.type=NodePort \
  jfrog/artifactory-jcr
```

To manually configure TLS, first create/retrieve a key & certificate pair for the address(es) you wish to protect. Then create a TLS secret in the namespace:

```bash
kubectl create secret tls artifactory-tls --cert=path/to/tls.cert --key=path/to/tls.key
```

Include the secret's name, along with the desired hostnames, in the Artifactory Ingress TLS section of your custom `values.yaml` file:

```yaml
artifactory:
  artifactory:
    ingress:
      ## If true, Artifactory Ingress will be created
      ##
      enabled: true

      ## Artifactory Ingress hostnames
      ## Must be provided if Ingress is enabled
      ##
      hosts:
        - jfrog-container-registry.domain.com
      annotations:
        kubernetes.io/tls-acme: "true"
      ## Artifactory Ingress TLS configuration
      ## Secrets must be manually created in the namespace
      ##
      tls:
        - secretName: artifactory-tls
          hosts:
            - jfrog-container-registry.domain.com
```

## Useful links
https://www.jfrog.com
https://www.jfrog.com/confluence/
