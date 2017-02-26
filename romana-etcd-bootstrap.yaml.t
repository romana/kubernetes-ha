apiVersion: v1
kind: Pod
metadata:
  labels:
    component: romana-etcd
    tier: control-plane
  name: romana-etcd
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: romana-etcd
    image: gcr.io/google_containers/etcd-amd64:3.0.14-kubeadm
    imagePullPolicy: IfNotPresent
    command:
    - etcd
    - --name=etcd-<node-number>
    - --listen-client-urls=http://127.0.0.1:12379,http://<host-ip>:12379
    - --listen-peer-urls=http://<host-ip>:12380
    - --advertise-client-urls=http://192.168.99.12:12379
    - --data-dir=/var/etcd/data
    - --initial-cluster=<initial-cluster>
    - --initial-advertise-peer-urls=http://<host-ip>:12380
    - --initial-cluster-state=new
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /health
        port: 2379
        scheme: HTTP
      initialDelaySeconds: 15
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /etc/ssl/certs
      name: certs
    - mountPath: /var/etcd
      name: romana-etcd
    - mountPath: /etc/kubernetes/
      name: k8s
      readOnly: true
  volumes:
  - hostPath:
      path: /etc/ssl/certs
    name: certs
  - hostPath:
      path: /var/lib/romana/etcd
    name: romana-etcd
  - hostPath:
      path: /etc/kubernetes
    name: k8s
