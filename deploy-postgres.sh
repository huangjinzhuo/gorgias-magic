#### Requirements ####

# 1. You have GCP account and password to login to GCP Cloud Console
# 2. You have a project, with the Kubernetes Engine API and Cloud Build API on the project enabled.
## Sign in to Google Cloud Platform Cloud Console with an account that has permission to manage the GKE
## GCP Cloud Console: https://console.cloud.google.com/
## select your project, or create a new one. 
## Make sure Kubernetes Engine API, and Cloud Build API on the project are enabled. If not:
## Navigation Menu - "APIs & Services" - "Library" - search for "Kuberetes" - "Kubernetes Engine API" - "Enable".
## Navigation Menu - "APIs & Services" - "Library" - search for "Build" - "Cloud Build API" - "Enable".
## click on  >_  to activate Cloud Shell from Cloud Console. All commands below are run in Cloud Shell



#### Get GKE cluster ready ####

# Set your GKE cluster name and assign it to env variable on your Cloud Shell
export CLUSTER_NAME=gorgias-magic

# Set user account, project, and other env variables
export GCP_USER=$(gcloud config get-value account)
export GCP_PROJECT=$(gcloud config get-value core/project)
(gcloud container clusters list  | grep $CLUSTER_NAME) && export CLUSTER_ZONE=$(gcloud container clusters list --format json | jq '.[] | select(.name=="'${CLUSTER_NAME}'") | .zone' | awk -F'"' '{print $2}')
(gcloud container clusters list  | grep $CLUSTER_NAME) || export CLUSTER_ZONE="us-central1-f"
gcloud config set compute/zone $CLUSTER_ZONE
export APP_DIR=$HOME/gorgias-magic

# Check if GKE cluster is running. If not, create it
(gcloud container clusters list  | grep $CLUSTER_NAME) || gcloud container clusters create gorgias-magic  --zone=$CLUSTER_ZONE --num-nodes 2

# Give yourself access to the cluster
gcloud container clusters get-credentials $CLUSTER_NAME \
--project $GCP_PROJECT \
--zone $CLUSTER_ZONE
kubectl create clusterrolebinding cluster-admin-binding \
--clusterrole cluster-admin \
--user $GCP_USER

# Find the application path. If not exist, download the application gorgias-magic
[ ! -d $APP_DIR ] && git clone https://github.com/huangjinzhuo/gorgias-magic.git 
cd $APP_DIR





#### Deploy Postgres master and replica ####

# Clone repository if it's not already in your home directory
# git clone https://github.com/huangjinzhuo/gorgias-magic.git
cd $APP_DIR/postgres

# For better security, edit postgres/secret.yaml to set new secrets for postgres-main and postgres-replica.
## vi postgres/secret.yaml
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

# Make sure master is running before next step: deploy Postgres replica 
while true; do
    POD_STATUS=${kubectl get pods postgres-0 -n default -o jsonpath='{.items.status.phase}'}
    if $POD_STATUS!=[]
    then
        echo "Checking pod status..."
        ${kubectl get pods -n default -o jsonpath='{.items[?(.status.phase != "Runninng" && .status.phase != "Succeeded")].metadata.name}: {.items[?(.status.phase != "Runninng" && .status.phase != "Succeeded")].status.phase}'}
    else
        exit
    fi
done

# Deploy Postgres replica 
kubectl apply -f postgres-replica.yaml

# Check replication
kubectl logs -f postgres-replica-0
