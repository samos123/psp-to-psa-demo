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
pe "kubectl get psp my-psp -o yaml"
#pe "kubectl get clusterrole my-psp -o yaml"
#pe "kubectl get clusterrolebinding psp-all-sa  -o yaml"
pe "cat nginx.yaml"
pe "kubectl apply -f nginx.yaml"
wait_available deployment/nginx-nonpriv
pe "kubectl get pod -l app=nginx -o json | jq '.items[].spec.containers'"
pe "# what do you notice? what's different between original nginx.yaml pod spec and k8s returned pod spec?"
pe "# notice it added the CHOWN capability?"

# Lets enable PSA and disable psp for default
pe "kubectl label --overwrite ns default pod-security.kubernetes.io/enforce=baseline"
pe "kubectl apply -f privileged-psp.yaml"
pe "kubectl create clusterrole privileged-psp --verb use --resource podsecuritypolicies.policy --resource-name privileged"
pe "kubectl create -n default rolebinding disable-psp --clusterrole privileged-psp --group system:serviceaccounts:default"

# lets redeploy our nginx deployment
pe "kubectl delete -f nginx.yaml"
pe "kubectl apply -f nginx.yaml"
pe "kubectl get pod -l app=nginx -o json | jq '.items[].spec.containers'"
pe "# what do you notice?"
pei "echo before with PSP the CHOWN capability was added but after migrating to PSA and redeploying our application, the CHOWN capability is gone."
pei "echo This could cause issues in production if not taken care of"


pe "cat nginx-with-chown.yaml"
pe "kubectl apply -f nginx-with-chown.yaml"
pe "kubectl get pod -l app=nginx -o json | jq '.items[].spec.containers'"

# cleanup
kubectl delete -f nginx.yaml > /dev/null
kubectl delete -f privileged-psp.yaml > /dev/null
kubectl delete -n default rolebinding disable-psp > /dev/null
kubectl delete clusterrole privileged-psp > /dev/null
kubectl label namespaces default pod-security.kubernetes.io/enforce- > /dev/null
