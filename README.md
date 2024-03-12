# AWS-cli-IAW
Este repositorio es para la práctica05.1 de anisble del módulo IAW

## Instalación AWS-CLI.
### Descargamos el archivo .zip que contiene la aplicación de AWS-CLI.
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```

### Descomprimimos con unzip (si no está instalado, instalarlo con apt install)
```
unzip awscliv2.zip
```

### Ejecutamos el script de instalación.
```
sudo ./aws/install
```

### Comprobamos la versión para ver si se instaló correctamente.
```
aws --version
```

## Configuración de AWS-CLI
### Ejecutamos el siguiente comando para comenzar con la configuración.
```
aws configure
```
En el, pondremos nuestras claves privadas de AWS. Las podemos encontrar en el laboratorio AWS details > Show
También pondremos region: us-east-1 y output: json

## Creación de scripts a ejecutar
### Creación grupos_seguridad.sh
```
#!/bin/bash
set -x

# Deshabilitamos la paginación de la salida de los comandos de AWS CLI
# Referencia: https://docs.aws.amazon.com/es_es/cli/latest/userguide/cliv2-migration.html#cliv2-migration-output-pager
export AWS_PAGER=""

# Importamos las variables de entorno
source .env

# CREACIÓN DE LOS GRUPOS DE SEGURIDAD.

# Creamos el grupo de seguridad: frontend-sg
aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_FRONTEND \
    --description "Reglas para el frontend"

# Creamos una regla de accesso SSH
aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_FRONTEND \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Creamos una regla de accesso HTTP
aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_FRONTEND \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

#---------------------------------------------------------------------

# Creamos el grupo de seguridad: backend-sg
aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_BACKEND \
    --description "Reglas para el backend"

# Creamos una regla de accesso SSH
aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_BACKEND \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Creamos una regla de accesso para MySQL
aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_BACKEND \
    --protocol tcp \
    --port 3306 \
    --cidr 0.0.0.0/0

# Creamos el grupo de seguridad: sg_nfs_iac
aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NFS \
    --description "Reglas para el servidor nfs"

# Creamos una regla de accesso SSH
aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_NFS \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Creamos una regla de accesso para nfs
aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_NFS \
    --protocol tcp \
    --port 2049 \
    --cidr 0.0.0.0/0


# Balanceador
# Creamos una regla de accesso HTTPs
aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_LOADBALANCER \
    --description "Reglas para el loadbalancer"

aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_LOADBALANCER \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0
# para el puerto 80
aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_LOADBALANCER \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
# para el puerto 22
aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_LOADBALANCER \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0
```
### Creación crear_instancias.sh
```
#!/bin/bash

set -x

# Deshabilitamos la paginación de la salida de los comandos de AWS CLI
# Referencia: https://docs.aws.amazon.com/es_es/cli/latest/userguide/cliv2-migration.html#cliv2-migration-output-pager
export AWS_PAGER=""

# Variables de configuración
source .env

# Creamos una instancia para el balanceador de carga.
aws ec2 run-instances \
    --image-id $AMI_ID \
    --count $COUNT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_LOADBALANCER \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_LOADBALANCER}]"

# Creamos las intancias EC2 para los frontends 1 y 2.
aws ec2 run-instances \
    --image-id $AMI_ID \
    --count $COUNT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_FRONTEND \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_FRONTEND_1}]"

aws ec2 run-instances \
    --image-id $AMI_ID \
    --count $COUNT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_FRONTEND \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_FRONTEND_2}]"

# Creamos una intancia EC2 para el backend
aws ec2 run-instances \
    --image-id $AMI_ID \
    --count $COUNT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_BACKEND \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_BACKEND}]"

# Creamos una instancia EC2 para el servidor nfs.

aws ec2 run-instances \
    --image-id $AMI_ID \
    --count $COUNT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_NFS \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_NFS}]"
```

### Creación ip_flontantes.sh
```
#!/bin/bash
set -x

# Deshabilitamos la paginación de la salida de los comandos de AWS CLI
# Referencia: https://docs.aws.amazon.com/es_es/cli/latest/userguide/cliv2-migration.html#cliv2-migration-output-pager
export AWS_PAGER=""

# Importamos las variables de entorno
source .env

# Obtenemos el Id de la instancia a partir de su nombre.
# Recoger el id de la instancia del frontend 1.
INSTANCE_ ID_frontend1=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=$INSTANCE_NAME_FRONTEND_1" \
                      "Name=instance-state-name,Values=running" \
            --query "Reservations[*].Instances[*].InstanceId" \
            --output text)

# Recoger el id de la instancia del frontend 2.
INSTANCE_ID_frontend2=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=$INSTANCE_NAME_FRONTEND_2" \
                      "Name=instance-state-name,Values=running" \
            --query "Reservations[*].Instances[*].InstanceId" \
            --output text)

# Recogemos el id de la instancia del backend.
#INSTANCE_ID_backend=$(aws ec2 describe-instances \
#            --filters "Name=tag:Name,Values=$INSTANCE_NAME_BACKEND" \
#                      "Name=instance-state-name,Values=running" \
#            --query "Reservations[*].Instances[*].InstanceId" \
#            --output text)

# Recogemos el id de la instancia del nfs.
INSTANCE_ID_nfs=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=$INSTANCE_NAME_NFS" \
                      "Name=instance-state-name,Values=running" \
            --query "Reservations[*].Instances[*].InstanceId" \
            --output text)

# Recogemos el id de la instancia del loadbalancer.
INSTANCE_ID_loadbalancer=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=$INSTANCE_NAME_LOADBALANCER" \
                      "Name=instance-state-name,Values=running" \
            --query "Reservations[*].Instances[*].InstanceId" \
            --output text)

# Creamos una IP elástica
ELASTIC_IP_f1=$(aws ec2 allocate-address --query PublicIp --output text)
ELASTIC_IP_f2=$(aws ec2 allocate-address --query PublicIp --output text)
#ELASTIC_IP_b=$(aws ec2 allocate-address --query PublicIp --output text)
ELASTIC_IP_nfs=$(aws ec2 allocate-address --query PublicIp --output text)
ELASTIC_IP_lb=$(aws ec2 allocate-address --query PublicIp --output text)

# Asociamos las ips a las máquinas.
aws ec2 associate-address --instance-id $INSTANCE_ID_frontend1 --public-ip $ELASTIC_IP_f1
aws ec2 associate-address --instance-id $INSTANCE_ID_frontend2 --public-ip $ELASTIC_IP_f2
#aws ec2 associate-address --instance-id $NSTANCE_ID_backend --public-ip $INSTANCE_NAME_BACKEND
aws ec2 associate-address --instance-id $INSTANCE_ID_nfs --public-ip $ELASTIC_IP_nfs
aws ec2 associate-address --instance-id $INSTANCE_ID_loadbalancer --public-ip $ELASTIC_IP_lb
```

### Creación del archivo de enviroment (.env)
```
# Instancias:
#Frontend 1 y 2
AMI_ID=ami-0c7217cdde317cfec 
COUNT=1 
INSTANCE_TYPE=t2.small 
KEY_NAME=vockey 
SECURITY_GROUP_FRONTEND=sg_frontend_iac
INSTANCE_NAME_FRONTEND_1=frontend_1_iac
#----------------------------------#
INSTANCE_NAME_FRONTEND_2=frontend_2_iac

# Backend.
SECURITY_GROUP_BACKEND="sg_backend_iac"
INSTANCE_NAME_BACKEND="backend_iac"

# Servidor NFS
SECURITY_GROUP_NFS="sg_nfs_iac" 
INSTANCE_NAME_NFS="nfs_iac"

# Servidor Balanceador de carga.
SECURITY_GROUP_LOADBALANCER=sg_load_balancer_iac
INSTANCE_NAME_LOADBALANCER=load_balancer_iac
```

## Ejecución de AWS-CLI
### Hay que seguir este orden para poder ejecutarlo correctamente.
#### 1. Ejecución del script grupos_seguridad.sh
```
./grupos_seguridad.sh

```
#### 2. Ejecución del script creacion_instancias.sh
```
./creacion_instancias.sh

```

#### 3. Ejecución del script ip_flotantes.sh
```
./ip_flotantes.sh

```
