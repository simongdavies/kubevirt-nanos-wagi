#!/bin/bash
set -euo pipefail

pushd -n $(pwd)

function cleanup()
{
    popd
}

trap cleanup EXIT

cd "$(dirname ${BASH_SOURCE[0]})/.."

usage()
{
    echo "Builds and pushes the container disk to be used with kubeVirt VM"
    echo "Usage: $0 -f disk-image-file -t tag -c context-path"
    exit 1
}

IMAGE_FILE_NAME="wagi.qcow2"
IMAGE_TAG="cnabquickstarts.azurecr.io/wagi:0.4.0"
DOCKER_CONTEXT="."

while getopts ":f:t:c:" opt; do
    case "${opt}" in
        f)  IMAGE_FILE_NAME=${OPTARG}
            ;;
        t)  IMAGE_TAG=${OPTARG}
            ;;
        c)  DOCKER_CONTEXT=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

docker build -t ${IMAGE_TAG} --build-arg disk_image=${IMAGE_FILE_NAME} ${DOCKER_CONTEXT}
docker push ${IMAGE_TAG}