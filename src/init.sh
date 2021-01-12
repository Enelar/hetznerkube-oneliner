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

hetzner-kube context add hko < /current_token > /dev/null 2>&1
hetzner-kube context use hko > /dev/null 2>&1
ssh-keygen -t rsa -f /keys/ssh_root > /dev/null 2>&1
hetzner-kube ssh-key add --name ssh_root --private-key-path /keys/ssh_root --public-key-path /keys/ssh_root.pub > /dev/null 2>&1

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

  "add_node")
    hetzner-kube cluster add-worker --name $1 --nodes 1
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


  *)
    echo "unknown"
    ;;
esac

cp -R /root/.hetzner-kube/* /keys/state
chown 1000:1000 -R /keys
