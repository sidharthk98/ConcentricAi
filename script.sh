#!/bin/bash
echo "--------------------Starting init scripts------------------------"
mkdir ~/.kube
export KUBECONFIG="/root/.kube/config"
export PATH="$PATH:/usr/local/bin"
export VERIFY_CHECKSUM=false 
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.23.6/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin
sudo yum install git kubectl openssl -y
aws eks update-kubeconfig --name private-eks --region us-east-1
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
./get_helm.sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
mkdir redis-volume
s3 cp  s3://workload-artifacts-cai/pv.yaml pv.yaml
s3 cp  s3://workload-artifacts-cai/pvc.yaml pvc.yaml
s3 cp  s3://workload-artifacts-cai/values.yaml values.yaml
sudo kubectl apply -f pv.yaml
sudo kubectl apply -f pvc.yaml
helm install my-redis-cluster bitnami/redis-cluster --kubeconfig /root/.kube/config -f values.yaml
echo "-----------------------Init execution complete--------------------------"