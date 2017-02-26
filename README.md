# kubernetes-ha
Instructions for creating a HA kubernetes cluster based on kubeadm's single-master deployment

# Create initial configuration

## Clone repo to /var/tmp

```bash
cd /var/tmp
git clone https://github.com/cgilmour/kubernetes-ha
cd kubernetes-ha
```

## Generate Root CA

```bash
./make_root_ca
```

## Generate kube-apiserver certificates

```bash
./make_apiserver_certs --dns-name your-apiserver.external.dns.name 192.168.99.10 192.168.99.11 192.168.99.12
```

## Generate service account keys

```bash
./make_sa_key
```

## Generate config for discovery service

```bash
./make_discovery_config your-apiserver.external.dns.name:6443
```

This will emit the discovery token. You'll need this to add minions later on.

## Generate kubelet config

```bash
./make_kubelet_conf your-apiserver.external.dns.name:6443
```

## Generate node-specific manifests

```bash
./make_manifests 192.168.99.10 192.168.99.11 192.168.99.12
```

# Bootstrap

## Copy configuration to each node

```bash
mkdir /var/tmp/ha-cluster
cd /var/tmp/ha-cluster
wget https://raw.githubusercontent.com/cgilmour/kubernetes-ha/master/install_files
chmod +x install_files
./install_files 192.168.99.10:/var/tmp/kubernetes-ha host-ip-of-node
```

## Start etcd

Connect to each master. On each node, run the command below.

```bash
sudo mv /etc/kubernetes/disabled-manifests/etcd-bootstrap.yaml /etc/kubernetes/manifests
```

Check it is launching appropriately with `docker ps` and `docker logs`.

# Start kubernetes components

```bash
sudo mv /etc/kubernetes/disabled-manifests/kube-*.yaml /etc/kubernetes/manifests
```

## Replace etcd-bootstrap with etcd

Once the kubernetes cluster is up on all three nodes and stable, its bootstrap configuration should be replaced with a stable config.
This should be run on each node. On each node, wait for the instance to recover and rejoin before doing another node.

```bash
sudo rm /etc/kubernetes/manifests/etcd-bootstrap.yaml
```
Wait for node to drop from the cluster
```bash
sudo mv /etc/kubernetes/disabled-manifests/etcd.yaml /etc/kubernetes/manifests
```
Wait for node to rejoin the cluster

# Add essential config and services

## Taint master nodes

For each master node, apply the taint as follows:

```bash
kubectl taint node node-name dedicated=master:NoSchedule
```

## Add kube-proxy

```bash
kubectl apply -f kube-proxy-daemonset.yaml
```

## Add cluster-info secret

```bash
kubectl apply -f clusterinfo-secret.yaml
```

## Add discovery service
```bash
kubectl apply -f kube-discovery-deployment.yaml
```

## Add kube-dns service

```bash
kubectl apply -f kube-dns-deployment.yaml
kubectl apply -f kube-dns-service.yaml
```

# Minion Nodes

## Find the host running the discovery service

Only one node will actually be running it. Use `kubectl -n kube-system get pods -o wide | grep kube-discovery` to find where it is.
For example purposes, below assumes it runs on node #3, 192.168.99.12

## Add a minion node

Find the discovery token from the earlier step. The example uses `afa67b.b5f052ecc18d8f8c`

```bash
kubeadm join --token=afa67b.b5f052ecc18d8f8c 192.168.99.12
```

# Romana Cluster

## Manifests

```bash
./make_romana_manifests 192.168.99.10 192.168.99.11 192.168.99.12
```

## Copy files to each node

```bash
wget https://raw.githubusercontent.com/cgilmour/kubernetes-ha/master/install_romana_files
chmod +x install_romana_files
./install_romana_files 192.168.99.10:/var/tmp/kubernetes-ha host-ip-of-node
```

## Start etcd

Connect to each master. On each node, run the command below.

```bash
sudo mv /etc/kubernetes/disabled-manifests/romana-etcd-bootstrap.yaml /etc/kubernetes/manifests
```

## Replace romana-etcd-bootstrap with romana-etcd

Once the kubernetes cluster is up on all three nodes and stable, its bootstrap configuration should be replaced with a stable config.
This should be run on each node. On each node, wait for the instance to recover and rejoin before doing another node.

```bash
sudo rm /etc/kubernetes/manifests/romana-etcd-bootstrap.yaml
```
Wait for node to drop from the cluster
```bash
sudo mv /etc/kubernetes/disabled-manifests/romana-etcd.yaml /etc/kubernetes/manifests
```
Wait for node to rejoin the cluster

## Add secret for romana-datastore

```bash
kubectl apply romana-datastore-secret.yaml
```

## Start romana-datastore

*NOTE*: This must be done in order, because of the way mariadb initializes a cluster.  The _first_ master node has a different configuration from other members.

```bash
sudo mv /etc/kubernetes/disabled-manifests/romana-datastore-bootstrap.yaml /etc/kubernetes/manifests
```

Wait for this to completely initialize before running it on other nodes.

## Replace romana-datastore-bootstrap with romana-datastore

```bash
sudo rm /etc/kubernetes/manifests/romana-datastore-bootstrap.yaml
```
Wait for node to drop from the cluster
```bash
sudo mv /etc/kubernetes/disabled-manifests/romana-datastore.yaml /etc/kubernetes/manifests
```
Wait for node to rejoin the cluster

## Install Romana

```bash
kubectl apply -f romana-cluster-kubeadm.yaml
```
