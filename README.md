
# Gorgias Magic Applicaiton


## Table of Contents
1. [Gorgias Magic](README.md#Gorgias-Magic)
1. [Requirements](README.md#Requirements)
1. [Platform Architecture](README.md#Platform-Architecture)
1. [Auto Deployment](README.md#Auto-Deployment)
1. [SRE Considerations](README.md#SRE-Considerations)






## Gorgias Magic

Gorgias Magic is a todo list application in Python. It's built on Flask framework and Postgres SQL. The instruction is for deploying the application to GCP Kubernetes Engine, with Google Cloud HTTP(S) Load Balancer as frontend. 

## Platform Architecture

![Platform Architecture](./platform_architecture.png?raw=true "Platform Architecture")


## Requirements

## Auto Deployment

Instructions here. 
Use Kubernetes StatefulSets to get a Postgres instance running with replication enabled. This also uses the [standard Postgres container](https://github.com/docker-library/postgres). Replication is achieved by streaming replcation instead of log shipping replication, and allow [warm standby.](https://www.postgresql.org/docs/current/warm-standby.html)


## SRE Considerations