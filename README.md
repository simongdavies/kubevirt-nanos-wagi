# Create WAGI VM in Kubernetes using KubeVirt

The scripts in this repo install [Kubevirt](https://kubevirt.io/) into a Kubernetes cluster and then create a VM running [WAGI](https://github.com/deislabs/wagi), the VM is running the [nanos](https://github.com/nanovms/nanos) unikernel.

If you already have a Kubernetes Cluster clone the repo and run:

```
../scripts/create-wagi-using-kubevirt.sh -n <namespace>
```

Otherwise to create a cluster in AKS run

```
# Namespace will default to wagi-ns if omitted.
# Resource Group should exist.
../scripts/create-cluster.sh -c <cluster-name> -g <resource-group> [-n <namespace>]
```

Once the VM is deployed the IP address of the wagi endpoint will be displayed and requests can be made to the wagi module in the image e.g:

```
 curl http://52.155.182.219
 Oh hi world
```


To clean up the VM delete the namespace 

```
kubectl delete ns <namespace>
```

To remove kubevirt from the cluster delete the kubevirt namespace

```
kubectl delete ns kubevirt
```