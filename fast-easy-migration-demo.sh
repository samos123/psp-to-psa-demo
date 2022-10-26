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
# maybe shorten or remove or show just basic cli output instead of yaml
pe "kubectl get clusterrole my-psp -o yaml"
pe "kubectl get clusterrolebinding psp-all-sa  -o yaml"
pe "cat nginx-priv.yaml"
pe "kubectl apply -f nginx-priv.yaml"
pe "kubectl describe deployment/nginx-priv"
pe "kubectl get events --field-selector reason=FailedCreate"
pe "kubectl delete -f nginx-priv.yaml"
pe "cat nginx-nonpriv.yaml"
pe "kubectl apply -f nginx-nonpriv.yaml"
wait_available deployment/nginx-nonpriv
pe "kubectl describe deployment/nginx-nonpriv"

# see which pod security standard would work for existing pods
# make sure to mention first running dry run and only applying after no warnings
pe "kubectl label --dry-run=server --overwrite ns default pod-security.kubernetes.io/enforce=restricted"
pe "kubectl label --dry-run=server --overwrite ns default pod-security.kubernetes.io/enforce=baseline"
# talk about how easy it's just to add a label to a namespace vs roles and rolebindings on SAs:
pe "kubectl label --overwrite ns default pod-security.kubernetes.io/enforce=baseline"
pe "kubectl label --overwrite ns default pod-security.kubernetes.io/warn=baseline"

# disable psp on namespace default it always prefers non mutating PSP that's why this works and
# why original PSP is no longer being active on the pod
pe "cat privileged-psp.yaml"
pe "kubectl apply -f privileged-psp.yaml"
pe "kubectl create clusterrole privileged-psp --verb use --resource podsecuritypolicies.policy --resource-name privileged"
pe "kubectl create -n default rolebinding disable-psp --clusterrole privileged-psp --group system:serviceaccounts:default"

# should see error like this now since PSP is disabled and PSA is active
# 2s Warning FailedCreate  replicaset/nginx-priv-8c9cd58b5         (combined from similar events): Error creating: pods "nginx-priv-8c9cd58b5-pxhxr" is forbidden: violates PodSecurity "baseline:latest": non-default capabilities (container "nginx" must not include "NET_ADMIN" in securityContext.capabilities.add), privileged (container "nginx" must not set securityContext.privileged=true)
pe "cat nginx-priv.yaml"
pe "kubectl apply -f nginx-priv.yaml"
pe "kubectl describe deployment/nginx-priv"
pe "kubectl get events --field-selector reason=FailedCreate --sort-by='.metadata.creationTimestamp' | tail -n 1"

# cleanup
kubectl delete -f nginx-nonpriv.yaml > /dev/null 2>&1
kubectl delete -f nginx-priv.yaml > /dev/null 2>&1
kubectl delete -f privileged-psp.yaml > /dev/null 2>&1
kubectl delete -n default rolebinding disable-psp > /dev/null 2>&1
kubectl delete clusterrole privileged-psp > /dev/null 2>&1
kubectl label namespaces default pod-security.kubernetes.io/enforce- > /dev/null
