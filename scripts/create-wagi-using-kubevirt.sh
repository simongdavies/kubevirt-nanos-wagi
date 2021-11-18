#!/bin/bash
set -euo pipefail

pushd -n $(pwd)

function cleanup()
{
    popd
}

trap cleanup EXIT

cd $( dirname "${BASH_SOURCE[0]}" )

usage()
{
    echo "Deploys kubevirt and then creates a VM running wagi using nanos in the cluster"
    echo "Usage: $0 [-n kubernetes-namespace-name ]"
    exit 1
}

NAMESPACE="wagi-ns"

while getopts ":n:" opt; do
    case "${opt}" in
        n)  NAMESPACE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

# Get the latest kubevirt version
export VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases | grep tag_name | grep -v -- '-rc' | sort -r | head -1 | awk -F': ' '{print $2}' | sed 's/,//' | xargs)
echo "Installing Kubevirt Version $VERSION"

# Install the kubevirt operator
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml

# Create custom resources 
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml

# Wait for deployment
while [[ $(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}") != "Deployed" ]];do 
    echo "Waiting for kubevirt deployment" && sleep 2
done

echo "Enabling Sidecar feature"

kubectl apply -f ../config/enablesidecars.yaml

echo "Ensuring Namespace exists"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name:  ${NAMESPACE}
EOF

echo "Creating Service"

kubectl apply -f ../config/service.yaml -n ${NAMESPACE}

SVC_IP_ADDRESS=""
echo "Waiting for Service IP Address"
while [[ -z ${SVC_IP_ADDRESS} ]]; do
    SVC_IP_ADDRESS=$(kubectl get svc wagi-http -n ${NAMESPACE} -o=jsonpath="{.status.loadBalancer.ingress[:1].ip}")
    if [[ -z "${SVC_IP_ADDRESS}" ]]; then
        sleep 2
    fi
done

echo "Creating Wagi VM"

kubectl apply -f ../config/wagi.yaml -n ${NAMESPACE}

# Wait for deployment
while [[ $(kubectl get vm/wagi -n ${NAMESPACE} -o=jsonpath="{.status.ready}") != "true" ]];do 
    echo "Waiting for VM" && sleep 1
done

VIRT_LAUNCHER_POD=$(kubectl get pods -l kubevirt.io/domain=wagi -n ${NAMESPACE} -o=jsonpath="{.items[:1].metadata.name}")

echo "Browse to/curl http://${SVC_IP_ADDRESS}"
echo "Logs from wagi VM:"

kubectl exec -it ${VIRT_LAUNCHER_POD} -n ${NAMESPACE} -c compute -- sh -c 'tail -f /var/run/serial0'