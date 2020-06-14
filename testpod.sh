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


#### Set variables ####

# Set user name, project name, and GKE cluster name on your Cloud Shell
export GCP_PROJECT=decoded-agency-280121
gcloud config set project $GCP_PROJECT
export GCP_USER=$(gcloud config get-value account)
export CLUSTER_NAME=gorgias-magic
# if [[ $GCP_PROJECT != $(gcloud config get-value core/project) ]]
# then
#     echo "Your selected project is not the intented project: ${GCP_PROJECT}"
#     read -p "Do you want to use the current project instead?(y/n) " -n 1 -r
#     if [[ $REPLY =~ ^[Yy]$ ]]
#     then
#         export GCP_PROJECT=$(gcloud config get-value core/project)
#         echo -e "\nNow project is set to $GCP_PROJECT"
#         sleep 2
#     fi
# fi

# Set Zone to the same as GKE cluster. If not exist, default 'us-central1-f'
(gcloud container clusters list  | grep $CLUSTER_NAME) && export CLUSTER_ZONE=$(gcloud container clusters list --format json | jq '.[] | select(.name=="'${CLUSTER_NAME}'") | .zone' | awk -F'"' '{print $2}')
(gcloud container clusters list  | grep $CLUSTER_NAME) || export CLUSTER_ZONE="us-central1-f"
gcloud config set compute/zone $CLUSTER_ZONE



#### Create Persistent Disks on Compute Engine for database volumes. 

# # Create Persitent Disks in GCE. (won't override if they already exist)
# gcloud compute disks create postgres-disk postgres-replica-disk  \
# --type=pd-ssd --size=20GB \
# --zone=$CLUSTER_ZONE --project=$GCP_PROJECT

# # Create a VM to use for formatting the persistent disks
# gcloud compute instances create formatter \
# --project=$GCP_PROJECT \
# --zone=us-central1-f \
# --machine-type=f1-micro \
# --disk=name=postgres-disk,device-name=postgres-disk,mode=rw,boot=no \
# --disk=name=postgres-replica-disk,device-name=postgres-replica-disk,mode=rw,boot=no 

# # Click on SSH for the formatter instance to open a Shell. Run this block of commands in the shell
# lsblk               # output NAME sdb, sdc could be the name of the disks to be formatted
# # Format the first disk (assume its name is sdb)
# sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
# # Format the second disk (assume its name is sdc)
# sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdc
# # Mount the disks and create a directory on each disk
# sudo mkdir /mnt/postgres
# sudo mkdir /mnt/postgres-replica
# sudo mount /dev/sdb /mnt/postgres
# sudo mount /dev/sdc /mnt/postgres-replica
# cd /mnt/postgres
# sudo mkdir postgres-db
# cd /mnt/postgres-replica
# sudo mkdir postgres-db
## Unmount the disks
# cd ~
# sudo umount /dev/sdb /dev/sdc

# # Back to the Cloud Console and auto confirm delete the formatter instance
# yes | gcloud compute instances delete formatter --project=$GCP_PROJECT --zone=us-central1-f



#### Get GKE cluster ready ####

# Check if GKE cluster is running. If not, create it
(gcloud container clusters list  | grep $CLUSTER_NAME) ||    \
gcloud beta container clusters create $CLUSTER_NAME  \
--zone=$CLUSTER_ZONE --num-nodes 2 \
--addons=GcePersistentDiskCsiDriver

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
#kubectl apply -f secret.yaml



# Create Storage Class, Persistent Volumes, Persistent Volume Claims
kubectl apply -f postgres-storage.yaml

# Deploy the Postgres master and wait till it's running
kubectl apply -f testdeployment.yaml

# Deploy Postgres service (for both posgres master and replica)
kubectl apply -f service.yaml

