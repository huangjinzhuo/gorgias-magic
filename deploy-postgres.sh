#### Requirements ####

# 1. You have a GCP account and password to login to GCP Cloud Console
# 2. You have a GCP project, with the Kubernetes Engine API and Cloud Build API on the project enabled.
## Sign in to Google Cloud Platform Cloud Console with an account that has permission to manage the GKE
## GCP Cloud Console: https://console.cloud.google.com/
## select your project, or create a new one. The project name be assigned to environment variable $GCP_PROJECT.
## Make sure Kubernetes Engine API, Cloud Build API, and Compute Engine API on the project are enabled. If not:
## Navigation Menu - "APIs & Services" - "Library" - search for "Kuberetes" - "Kubernetes Engine API" - "Enable".
## Navigation Menu - "APIs & Services" - "Library" - search for "Build" - "Cloud Build API" - "Enable".
## Navigation Menu - "APIs & Services" - "Library" - search for "Compute" - "Compute Engine API" - "Enable".
## click on  >_  to activate Cloud Shell from Cloud Console. All commands below are run in Cloud Shell



# Find the application path. If not exist, download the application gorgias-magic
export APP_DIR=$HOME/gorgias-magic
[ ! -d $APP_DIR ] && cd $HOME && git clone https://github.com/huangjinzhuo/gorgias-magic.git 
cd $APP_DIR
# Now you can see this file at current directory. And you can continue this script step by step. Or just run
# . deploy-postgres.sh          # Don't forget the dot(.) at the beginning


#### Get GKE cluster ready ####

# Set your GKE cluster name and assign it to env variable on your Cloud Shell
export CLUSTER_NAME=gorgias-magic
export GCP_PROJECT=gorgias-magic-777
if [[ $GCP_PROJECT != $(gcloud config get-value core/project) ]]
then
    echo "Your selected project is not the intented project: ${GCP_PROJECT}"
    read -p "Do you want to use the current project instead?(y/n) " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        export GCP_PROJECT=$(gcloud config get-value core/project)
        echo -e "\nNow project is set to $GCP_PROJECT"
        sleep 2
    fi
fi


# Set user account, and other env variables
export GCP_USER=$(gcloud config get-value account)
(gcloud container clusters list  | grep $CLUSTER_NAME) && export CLUSTER_ZONE=$(gcloud container clusters list --format json | jq '.[] | select(.name=="'${CLUSTER_NAME}'") | .zone' | awk -F'"' '{print $2}')
(gcloud container clusters list  | grep $CLUSTER_NAME) || export CLUSTER_ZONE="us-central1-f"
gcloud config set compute/zone $CLUSTER_ZONE


# Check if GKE cluster is running. If not, create it
(gcloud container clusters list  | grep $CLUSTER_NAME) || gcloud container clusters create $CLUSTER_NAME  --zone=$CLUSTER_ZONE --num-nodes 2

# Give yourself access to the cluster
gcloud container clusters get-credentials $CLUSTER_NAME \
--project $GCP_PROJECT \
--zone $CLUSTER_ZONE
kubectl create clusterrolebinding cluster-admin-binding \
--clusterrole cluster-admin \
--user $GCP_USER




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

# Create Persitent Disks in GCE. (won't override if they already exist)
gcloud compute disks create postgres-disk postgres-replica-disk --size 20GB --zone=$CLUSTER_ZONE

# Deploy the Postgres master and wait till it's running
kubectl apply -f postgres-master.yaml
# Deploy Postgres service (for both posgres master and replica)
kubectl apply -f service.yaml

# Make sure master is running before next step: deploy Postgres replica 
while true; do
    POD_STATUS=$(kubectl get pods |grep postgres-0 | awk '{print $3}' ) 
    echo $POD_STATUS
    if [[ $POD_STATUS != "Running" ]]
    then
        echo ""
        echo "Postgres-0 is not ready. Checking pod status..."
        kubectl get pods |grep postgres-0
        echo "Sleep for 5 seconds"
        sleep 5
    else
        echo "=========== Postgres-0 is ready ============"
        break
    fi
done

# Deploy Postgres replica 
kubectl apply -f postgres-replica.yaml

# Check replication
kubectl logs -f postgres-replica-0 | grep "started streaming WAL from primary"
# If you see "Started streaming WAL from primary", the replication is working.





#### Clean up (delete everything that's created with this script) ####

# ## Delete deployments, services, configmaps, and secrets.
# kubectl delete -f postgres-replica.yaml
# kubectl delete -f service.yaml
# kubectl delete -f postgres-master.yaml
# kubectl delete configmap postgres
# kubectl delete -f secret.yaml

# ## You have to decide to keep or delete the storage.
# # Go to GCP Console -> Kubernetes Engine -> Storage, and review the storage you want to delete, and delete from there.
# # Also check here: GCP Console -> Compute Engine -> Disk

# ## You also want to double check if the GKE cluster was created or pre-exiting. 
# ## Be careful not to delete other deployments that use the same cluster.
# gcloud container clusters delete $CLUSTER_NAME --zone=$CLUSTER_ZONE

