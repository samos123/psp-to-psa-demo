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


TYPE_SPEED=40
# Demonstrate PSP is currently active
pe "cat psp-policy.yaml"
pe "cat nginx-nonpriv.yaml"
pe "kubectl apply -f nginx-nonpriv.yaml"
pe "cat nginx-html-configmap.yaml"
wait_available deployment/nginx-nonpriv
pe "kubectl get pod -l app=nginx -o json | jq '.items[].spec.containers'"
pe "kubectl get pod -l app=nginx -o json | jq '.items[].spec.securityContext'"
pe "kubectl port-forward service/nginx 8080:80"

# Lets enable PSA
pe "kubectl label --overwrite ns default pod-security.kubernetes.io/enforce=baseline"
# disable psp for default namespace
pe "kubectl apply -f privileged-psp.yaml"
pe "kubectl create clusterrole privileged-psp --verb use --resource podsecuritypolicies.policy --resource-name privileged"
pe "kubectl create -n default rolebinding disable-psp --clusterrole privileged-psp --group system:serviceaccounts:default"

# lets redeploy our nginx deployment
pe "kubectl rollout restart deployment/nginx-nonpriv"
pe "kubectl port-forward service/nginx 8080:80"
pe "kubectl get pod -l app=nginx -o json | jq '.items[].spec.containers'"
pe "kubectl get pod -l app=nginx -o json | jq '.items[].spec.securityContext'"
#pe "cat Dockerfile"


pe "cat nginx-with-security-context.yaml"
pe "kubectl apply -f nginx-with-security-context.yaml"
pe "kubectl port-forward service/nginx 8080:80"

# cleanup
kubectl delete -f nginx-nonpriv.yaml > /dev/null
kubectl delete -f privileged-psp.yaml > /dev/null
kubectl delete -n default rolebinding disable-psp > /dev/null
kubectl delete clusterrole privileged-psp > /dev/null
kubectl label namespaces default pod-security.kubernetes.io/enforce- > /dev/null
