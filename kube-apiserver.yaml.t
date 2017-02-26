apiVersion: v1
kind: Pod
metadata:
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-apiserver
    image: gcr.io/google_containers/kube-apiserver-amd64:v1.5.3
    imagePullPolicy: IfNotPresent
    command:
    - kube-apiserver
    - --apiserver-count=<masters>
    - --insecure-bind-address=127.0.0.1
    - --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota
    - --service-cluster-ip-range=10.96.0.0/12
    - --service-account-key-file=/etc/kubernetes/pki/sa-pub.pem
    - --client-ca-file=/etc/kubernetes/pki/ca.pem
    - --tls-cert-file=/etc/kubernetes/pki/apiserver.pem
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver-key.pem
    - --token-auth-file=/etc/kubernetes/pki/tokens.csv
    - --secure-port=6443
    - --allow-privileged
    - --advertise-address=<host-ip>
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
    - --anonymous-auth=false
    - --etcd-servers=<etcd-servers>
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 8080
        scheme: HTTP
      initialDelaySeconds: 15
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /etc/kubernetes/
      name: k8s
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: certs
  volumes:
  - hostPath:
      path: /etc/kubernetes
    name: k8s
  - hostPath:
      path: /etc/ssl/certs
    name: certs
