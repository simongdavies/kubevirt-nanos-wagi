#!/bin/bash
set -euo pipefail

pushd -n $(pwd)

function cleanup()
{
    popd
    if [[ ${CURRENT_CONTEXT} ]]; then 
        echo "Setting context to ${CURRENT_CONTEXT}"
        kubectl config set-context ${CURRENT_CONTEXT}
    fi
}

trap cleanup EXIT

# Get current context 

CURRENT_CONTEXT=$(kubectl config current-context)
if [[ ${CURRENT_CONTEXT} ]]; then 
	echo "Current Context is ${CURRENT_CONTEXT}"
fi

cd $( dirname "${BASH_SOURCE[0]}" )

usage()
{
    echo "Creates a new AKS Cluster, deploys kubevirt and then creates a VM running wagi using nanos in the cluster"
    echo "Log into azure before runninig this script"
    echo "Azure resource group should be created before running this script"
    echo "Usage: $0 -c cluster-name -g resource-group" [-n kubernetes-namespace-name ]
    exit 1
}

CLUSTER_NAME=""
RESOURCE_GROUP=""
NAMESPACE=""

while getopts ":c:g:n:" opt; do
    case "${opt}" in
        c)
            CLUSTER_NAME=${OPTARG}
            ;;
        g)
            RESOURCE_GROUP=${OPTARG}
            ;;
        n)  
            NAMESPACE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "${CLUSTER_NAME}" ] || [ -z "${RESOURCE_GROUP}" ]; then
    usage
fi

if [[ -z $(az group show -g "${RESOURCE_GROUP}" 2>/dev/null) ]]; then  
    echo "Resource Group "${RESOURCE_GROUP}" does not exist";
    exit 1; 
fi

echo "Creating New AKS Cluster"

az aks create --resource-group ${RESOURCE_GROUP} --node-vm-size Standard_D4s_v3 --node-count 1 --name ${CLUSTER_NAME} --no-ssh-key --nodepool-labels vms=true 

# Get credetials and set kube context 

az aks get-credentials -n ${CLUSTER_NAME} -g ${RESOURCE_GROUP} --admin

source ./create-wagi-using-kubevirt.sh -n "${NAMESPACE}"