apiVersion: v1
kind: Pod
metadata:
  labels:
    component: romana-datastore
    tier: control-plane
  name: romana-datastore
  namespace: kube-system
spec:
  containers:
  - env:
    - name: MYSQL_ROOT_PASSWORD
      valueFrom:
        secretKeyRef:
          name: romana-secrets
          key: datastore-password
    image: mariadb:10
    imagePullPolicy: IfNotPresent
    name: romana-datastore
    args:
    - --binlog-format=ROW
    - --default-storage-engine=InnoDB
    - --innodb-autoinc-lock-mode=2
    - --bind-address=0.0.0.0
    - --wsrep-on=ON
    - --wsrep-provider=/usr/lib/galera/libgalera_smm.so
    - --wsrep-cluster-name=romana-datastore
    - --wsrep-cluster-address=gcomm://<datastore-nodes>
    - --wsrep-sst-method=rsync
    - --wsrep-node-address=<host-ip>
    - --wsrep-node-name=romana-datastore-<node-number>
    - --wsrep-new-cluster
    volumeMounts:
    - mountPath: /var/lib
      name: mysql-data
  hostNetwork: true
  restartPolicy: Always
  volumes:
  - hostPath:
      path: /var/lib/romana/mysql-db
    name: mysql-data

