# Requirements:
# 1. You have a GCP Project created
# 2. You have GCP account and password to login to GCP Cloud Console



# Set ENV variables.  
export POSTGRES_DB_USER="postgres"
export POSTGRES_DB_PSWD="postgres"
export SERVICE_POSTGRES_SERVICE_HOST="127.0.0.1"

# Edit postgres/secret.yaml to match with the user name and password


#### Deploy Postgres master and replica ####

# Clone repository
git clone https://github.com/huangjinzhuo/gorgias-magic.git

# Create configmap
kubectl apply -f ./postgres/secret.yaml
cd postgress
kubectl create configmap postgres \
--from-file=postgres.conf \
--from-file=master.conf \
--from-file=replica.conf \
--from-file=pg_hba.conf \
--from-file=create-replica-user.sh

# Deploy the Postgres master and wait till it's running
kubectl apply -f postgres-master.yaml
# Deploy Postgres service
kubectl apply -f service.yaml

# (Make sure master is running, first) deploy Postgres replica 
kubectl apply -f postgres-replica.yaml

# Check replication
kubectl logs -f postgres-replica-0


#### Deploy Flask application ####

