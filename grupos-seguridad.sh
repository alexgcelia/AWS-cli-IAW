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