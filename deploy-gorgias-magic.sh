# Requirements: 
# 1. You have GCP account and password to login to GCP Cloud Console
# 2. You have a project, and Kubernetes Engine API on the project is enabled.

# Sign in to Google Cloud Platform Cloud Console with an account that has permission to manage the GKE
# GCP Cloud Console: https://console.cloud.google.com/
# select your project. 
# Make sure Kubernetes Engine API on the project is enabled:
# Navigation Menu - "APIs & Services" - "Library" - search for "Kuberetes" - "Kubernetes Engine API" - "Enable".
# click on  >_  to activate Cloud Shell from Cloud Console. All commands below are run in Cloud Shell

# assign cluster name variable
export CLUSTER_NAME=gorgias-magic

# get user account, project, and other env variables
export GCP_USER=$(gcloud config get-value account)
export GCP_PROJECT=$(gcloud config get-value core/project)
(gcloud container clusters list  | grep $CLUSTER_NAME) && export CLUSTER_ZONE=$(gcloud container clusters list --format json | jq '.[] | select(.name=="'${CLUSTER_NAME}'") | .zone' | awk -F'"' '{print $2}')
(gcloud container clusters list  | grep $CLUSTER_NAME) || export CLUSTER_ZONE="us-central1-f"
export APP_ZONE=$CLUSTER_ZONE
export APP_DIR=$HOME/gorgias-magic
gcloud config set compute/zone $CLUSTER_ZONE

# Set ENV variables.  
# export POSTGRES_DB_USER="postgres"
# export POSTGRES_DB_PSWD="postgres"
# export SERVICE_POSTGRES_SERVICE_HOST="127.0.0.1"


# check if GKE cluster is running, if not create it
(gcloud container clusters list  | grep $CLUSTER_NAME) || gcloud container clusters create gorgias-magic  --zone=$APP_ZONE --num-nodes 2

# give yourself access to the cluster
gcloud container clusters get-credentials $CLUSTER_NAME \
--project $GCP_PROJECT \
--zone $CLUSTER_ZONE
kubectl create clusterrolebinding cluster-admin-binding \
--clusterrole cluster-admin \
--user $GCP_USER




# find application path. If not exist, download gorgias-magic
[ ! -d $APP_DIR ] && git clone https://github.com/huangjinzhuo/gorgias-magic.git 
cd $APP_DIR





#### Deploy Postgres master and replica ####

# Clone repository if it's not already in your home directory
# git clone https://github.com/huangjinzhuo/gorgias-magic.git
cd $APP_DIR/postgres

# Edit postgres/secret.yaml to set new secrets for postgres-main and postgres-replica.

########### vi postgres/secret.yaml
########### kubectl apply -f secret.yaml
kubectl apply -f secret.yaml
# Create configmap
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

