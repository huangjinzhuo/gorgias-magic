#### Requirements ####

# 1. You have a GCP account and password to login to GCP Cloud Console
# 2. You have a GCP project, with the Kubernetes Engine API and Cloud Build API on the project enabled.
## Sign in to Google Cloud Platform Cloud Console with an account that has permission to manage the GKE
## GCP Cloud Console: https://console.cloud.google.com/
## select your project, or create a new one. The project name be assigned to environment variable $GCP_PROJECT.
## Make sure Kubernetes Engine API, and Cloud Build API on the project are enabled. If not:
## Navigation Menu - "APIs & Services" - "Library" - search for "Kuberetes" - "Kubernetes Engine API" - "Enable".
## Navigation Menu - "APIs & Services" - "Library" - search for "Build" - "Cloud Build API" - "Enable".
## click on  >_  to activate Cloud Shell from Cloud Console. All commands below are run in Cloud Shell



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
export APP_DIR=$HOME/gorgias-magic


# # Set env variables for connecting to local PostgreSQL for local testing only. For PostgreSQL deployed in the cloud, these variables are set through yaml file such as flask-deployment.yaml
# export POSTGRES_DB_USER="postgres"
# export POSTGRES_DB_PSWD="postgres"
# export POSTGRES_SERVICE_HOST="127.0.0.1"
# export POSTGRES_SERVICE_PORT="5432"
# export POSTGRES_DB_NAME="postgres"

# Check if GKE cluster is running. If not, exit
(gcloud container clusters list  | grep $CLUSTER_NAME) || (echo "GKE cluster and database engine are not ready.Run deploy-postgres.sh to create them." && sleep 10 && exit)

# Give yourself access to the cluster
gcloud container clusters get-credentials $CLUSTER_NAME \
--project $GCP_PROJECT \
--zone $CLUSTER_ZONE
kubectl create clusterrolebinding cluster-admin-binding \
--clusterrole cluster-admin \
--user $GCP_USER


# Make sure database engine (Postgres master) is running. If not, exit 
POD_STATUS=$(kubectl get pods |grep postgres-0 | awk '{print $3}' ) 
echo $POD_STATUS
if [[ $POD_STATUS != "Running" ]]
then
    echo ""
    echo "Postgres-0 is not ready. Run deploy-postgres.sh to deploy." 
    sleep 10 && exit
fi


# Find the application path. If not exist, download the application gorgias-magic
[ ! -d $APP_DIR ] && git clone https://github.com/huangjinzhuo/gorgias-magic.git 





#### Deploy Flask application ####

# Build Docker image 
cd $APP_DIR
gcloud builds submit -t gcr.io/$GCP_PROJECT/gorgias-magic ./

# Dedploy the Flask app and Flask service
kubectl apply -f flask-deployment.yaml
kubectl apply -f flask-service.yaml

# Wait for deployment ready
while true; do
    POD_STATUS=$(kubectl get pods | grep flask-app | awk '{print $3}' ) 
    echo $POD_STATUS
    if [[ $POD_STATUS != "Running" ]]
    then
        echo ""
        echo "Gorgias deployment is not ready. Checking pod status..."
        kubectl get pods |grep flask-app
        echo "Sleep for 10 seconds"
        sleep 10
    else
        echo "================= Gorgias Magic  is ready ================="
        echo "You can connect to the application via http://<EXTERNAL-IP>"
        break
    fi
done

# Display service EXTERNAL-IP
kubectl get services gorgias-service
