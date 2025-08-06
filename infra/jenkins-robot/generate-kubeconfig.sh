#!/bin/bash
set -e

cd "$(dirname "$0")"

NAMESPACE=${1:-infra}
SA_NAME=${2:-jenkins-robot}

echo "Creating Kubernetes resources..."
kubectl apply -f serviceaccount.yaml
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml
kubectl apply -f clusterrole.yaml

echo "Creating permanent service account token secret..."
kubectl apply -f secret.yaml

echo "Waiting for secret to be created and token to be generated..."
sleep 5

echo "Getting cluster information..."
CLUSTER_NAME=$(kubectl config view -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')

SECRET_NAME=$(kubectl get secret -n $NAMESPACE | grep jenkins-robot-secret | awk '{print $1}')
USER_TOKEN=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.token}' | base64 -d | tr -d '\n')
CLUSTER_CA=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')

if [ -z "$USER_TOKEN" ]; then
    echo "ERROR: Failed to extract token from secret $SECRET_NAME"
    echo "Checking if secret exists..."
    kubectl get secret $SECRET_NAME -n $NAMESPACE
    exit 1
fi

if [ -z "$CLUSTER_CA" ]; then
    echo "ERROR: Failed to extract CA certificate from secret $SECRET_NAME"
    exit 1
fi

echo "Creating kubeconfig file..."
cat > ${SA_NAME}.kubeconfig <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    namespace: ${NAMESPACE}
    user: ${SA_NAME}
  name: ${SA_NAME}@${CLUSTER_NAME}
current-context: ${SA_NAME}@${CLUSTER_NAME}
users:
- name: ${SA_NAME}
  user:
    token: ${USER_TOKEN}
EOF

echo "Created kubeconfig file: ${SA_NAME}.kubeconfig"
echo "Token length: ${#USER_TOKEN} characters"
echo "CA certificate length: ${#CLUSTER_CA} characters"
