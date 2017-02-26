apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: clusterinfo
  namespace: kube-system
data:
  ca.pem: <ca-pem-base64>
  endpoint-list.json: <endpoint-list-base64>
  token-map.json: <token-map-base64>
