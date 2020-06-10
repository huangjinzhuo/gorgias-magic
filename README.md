
# Gorgias Magic Applicaiton


## Table of Contents
1. [Gorgias Magic](README.md#What-is-Gorgias-Magic?)
1. [Requirements](README.md#Requirements)
1. [Platform Architecture](README.md#Platform-Architecture)
1. [Auto Deployment](README.md#Auto-Deployment)
1. [SRE Considerations](README.md#SRE-Considerations)



## What is Gorgias Magic?

Gorgias Magic is a todo list application written Python. It's built on Flask framework and uses Postgres SQL. The instruction is for deploying a Postgres cluster, and the application to a GCP Kubernetes Engine(GKE) cluster. The instruction will also automatically create the GKE clustetr if it's not exist, and automatically create a Google Cloud HTTP Load Balancer to serve in the frontend. 

## Platform Architecture

![Platform Architecture](./magic_app_architecture.png?raw=true "Platform Architecture")


## Requirements

1. You have a GCP account and password to login to [GCP Cloud Console](https://console.cloud.google.com/),
2. You have a project, and Kubernetes Engine API and Cloud Build API on the project are enabled. [Here is the instruction on how to enable them](Other_README.md#Enable-APIs)

## Deployment

### Deploying a Postgres cluster

Use Kubernetes StatefulSets to get a Postgres instance running with replication enabled. This also uses the [standard Postgres container](https://github.com/docker-library/postgres). Replication is achieved by streaming replcation instead of log shipping, and allow [warm standby.](https://www.postgresql.org/docs/current/warm-standby.html)

1. run batch script to deploy Postgres cluster:             . deploy-postgres.sh
2. run interactive script to create database and table:     create-db.sh
3. run batch script to deploy Gorgias Magic application:    . deploy-gorgias-magic.sh
4. follow the last message of step 3 to find out EXTERNAL-IP. There are 4 links:
    http://<EXTERNAL-IP>                                        Readiness Probe page.
    http://<EXTERNAL-IP>/all                                    List all todo entries.
    http://<EXTERNAL-IP>/<todo-description>/<number-of-days>    Create a todo entry. For example:   http://34.70.91.51/pickup%20some%20milk/2
    http://<EXTERNAL-IP>/<todo-description>                     List a todo entry



## SRE Considerations


