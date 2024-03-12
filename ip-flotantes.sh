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

