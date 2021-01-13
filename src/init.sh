#!/bin/bash

if [ ! -f /keys/API_TOKEN ]; then
    echo "API_TOKEN file is required. Did you forget to create /keys volume?"
    exit 1
fi

TOKEN="$(</keys/API_TOKEN)
"

echo $TOKEN > /current_token

cp -R /keys/state /root/.hetzner-kube
chown root:root /root/.hetzner-kube

if [ ! -f /root/.hetzner-kube/config.json ]; then 
  hetzner-kube context add hko < /current_token > /dev/null 2>&1
  hetzner-kube context use hko > /dev/null 2>&1
fi
ssh-keygen -t rsa -f /keys/ssh_root > /dev/null 2>&1
hetzner-kube ssh-key add --name hko_ssh_root --private-key-path /keys/ssh_root --public-key-path /keys/ssh_root.pub > /dev/null 2>&1

case $1 in
  "help")
    hetzner-kube help $2
    ;;

  "list")
    hetzner-kube cluster list
    ;;

  "shell")
    echo "Running: $2 $3 $4 $5 $6 $7 $8 $9"
    hetzner-kube $2 $3 $4 $5 $6 $7 $8 $9
    ;;
esac

case $2 in

  "init")
    hetzner-kube cluster create --name $1 --ssh-key ssh_root --master-count 1 --worker-count 1

    ;;

  "add-node")
    hetzner-kube cluster add-worker --name $1 --nodes 1
    ;;

  "del-node")
    hetzner-kube cluster remove-worker --name $1 --worker $3
    ;;

  "destroy")
    hetzner-kube cluster delete $1
    ;;

  "master-ip")
    hetzner-kube cluster master-ip $1
    ;;

  "config")
    hetzner-kube cluster kubeconfig $1
    cp /root/.kube/config config

    yq -i -y '.["current-context"] = "hko-admin-'$1'@hko-'$1'"' config
    yq -i -y '.contexts[0].context.cluster = "hko-'$1'"' config
    yq -i -y '.contexts[0].context.user = "hko-admin-'$1'"' config
    yq -i -y '.contexts[0].name = "hko-admin-'$1'@hko-'$1'"' config
    yq -i -y '.clusters[0].name = "hko-'$1'"' config
    yq -i -y '.users[0].name = "hko-admin-'$1'"' config
    
    mkdir /keys/config > /dev/null 2>&1
    cp config /keys/config/$1
    ;;

  "init-storage")
    hetzner-kube cluster kubeconfig $1

    echo "Expected Server version: 1.18+"
    kubectl version --short 
  
    kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.5.1/deploy/kubernetes/hcloud-csi.yml

    TOKEN_ONELINE=`echo "${TOKEN}" | head -1`
    yq -i -y '.stringData.token = "'$TOKEN_ONELINE'"' /csi-secret.yml
    kubectl apply -f /csi-secret.yml

    echo "CSI uses ~ 16MB on each node + 60Mb"
    ;;

  "init-helm")
    hetzner-kube cluster kubeconfig $1

    kubectl -n kube-system create serviceaccount tiller
    kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
    helm init --service-account=tiller

    mkdir /keys/helm > /dev/null 2>&1
    cp -R /root/.helm /keys/helm/$1

    echo "Tiler uses ~ 30MB"
    ;;

  "delete-helm")
    hetzner-kube cluster kubeconfig $1
    kubectl -n kube-system delete deployment tiller-deploy
    kubectl delete clusterrolebinding tiller
    kubectl -n kube-system delete serviceaccount tiller
    ;;

  "helm")
    hetzner-kube cluster kubeconfig $1 > /dev/null 2>&1
    helm init --service-account=tiller --client-only > /dev/null 2>&1
    helm $2 $3 $4 $5 $6 $7 $8 $9

    ;;

  *)
    echo "command unknown"
    ;;
esac

cp -R /root/.hetzner-kube/* /keys/state
chown 1000:1000 -R /keys
