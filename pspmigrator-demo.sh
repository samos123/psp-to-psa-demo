#!/usr/bin/env bash
########################
# include the magic
########################
. demo-magic.sh

# hide the evidence
clear

wait_ready() {
  kubectl wait --for=condition=Ready $1 > /dev/null
}

wait_available() {
  kubectl wait --for=condition=Available $1 > /dev/null
}


# Demonstrate PSP is currently active
#pe "kubectl get psp my-psp -o yaml"
#pe "kubectl get clusterrole my-psp -o yaml"
#pe "kubectl get clusterrolebinding psp-all-sa  -o yaml"
pe "cat nginx.yaml"
pe "kubectl apply -f nginx.yaml"
wait_available deployment/nginx-nonpriv
pe "kubectl get pod -l app=nginx -o json | jq '.items[].spec.containers'"

# lets use pspmigrator to detect and migrate default namespace
p "go install github.com/kubernetes-sigs/pspmigrator/cmd/pspmigrator"
pe "pspmigrator mutating pods"
pe "pspmigrator mutating psp my-psp"
pe "pspmigrator migrate"
POD_NAME=$(kubectl get pod -l app=nginx --no-headers -o custom-columns=":metadata.name")
pe "pspmigrator mutating pod $POD_NAME -n default"
pe "cat nginx-with-chown.yaml"
pe "kubectl apply -f nginx-with-chown.yaml"
pe "pspmigrator migrate"
pe "pspmigrator migrate --dry-run=false"
pe "kubectl get ns default -o yaml"

# Lets disable psp for default
# pe "kubectl apply -f privileged-psp.yaml"
# pe "kubectl create clusterrole privileged-psp --verb use --resource podsecuritypolicies.policy --resource-name privileged"
# pe "kubectl create -n default rolebinding disable-psp --clusterrole privileged-psp --group system:serviceaccounts:default"

# cleanup
kubectl delete -f nginx.yaml > /dev/null 2>&1
kubectl delete -f nginx-priv.yaml > /dev/null 2>&1
kubectl delete -f privileged-psp.yaml > /dev/null 2>&1
kubectl delete -n default rolebinding disable-psp > /dev/null 2>&1
kubectl delete clusterrole privileged-psp > /dev/null 2>&1
kubectl label namespaces default pod-security.kubernetes.io/enforce- > /dev/null 2>&1
