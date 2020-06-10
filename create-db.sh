#### Instruction to create a PostgreSQL database (magicdb) and create a table (todos) ####

# ## Requirements:
# #1. This is a script that needs interactive. Can't be used as a bath file.
# #2. Finished the deployment of Postgres cluster by running deploy-postgres.sh 
# #3. You are still in the same Bash session where you ran deploy-postgres.sh. Otherwise you need to set the following env variables, and give yourself access to the cluster:
#       export CLUSTER_NAME=gorgias-magic
#       export GCP_PROJECT=$(gcloud config get-value core/project)
#       export GCP_USER=$(gcloud config get-value account)
#       (gcloud container clusters list  | grep $CLUSTER_NAME) && export CLUSTER_ZONE=$(gcloud container clusters list --format json | jq '.[] | select(.name=="'${CLUSTER_NAME}'") | .zone' | awk -F'"' '{print $2}')
#       (gcloud container clusters list  | grep $CLUSTER_NAME) || export CLUSTER_ZONE="us-central1-f"
#       gcloud config set compute/zone $CLUSTER_ZONE
#       export APP_DIR=$HOME/gorgias-magic
# Give yourself access to the cluster
#       gcloud container clusters get-credentials $CLUSTER_NAME \
#       --project $GCP_PROJECT \
#       --zone $CLUSTER_ZONE
#       kubectl create clusterrolebinding cluster-admin-binding \
#       --clusterrole cluster-admin \
#       --user $GCP_USER




#### Connect to the Postgres pod in GKE cluster ####

# Check the postgres pod status
kubectl get pods postgres-0

# Connect to postgres-0
kubectl exec -it postgres-0 -- /bin/bash        # Now you are at the Pod as the root user.
                                                # If not in as root, run this extra command:   su - 
su - postgres                                   # Login with user postgres
psql                                            # Now you are in Postgresql Shell with this prompt: postgres=#

# Create database and table by coping the following block to Postgresql Shell
# It's ok if you get error because they are already exist:
CREATE DATABASE magicdb;
\q
psql -d magicdb
CREATE TABLE todos(
     id INTEGER GENERATED ALWAYS AS IDENTITY,
     PRIMARY KEY(id),
     todo TEXT NOT NULL,
     days INTEGER
);


# You are done. Enter \q to exit, then enter exit 2 times to get to the Cloud Shell,
postgres=# \q
postgres@postgres-0:~$ exit
root@postgres-0:/# exit