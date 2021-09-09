#!/usr/bin/env bash
CURRENT_CONTEXT=$(kubectl config current-context)
SEALED_SECRETS_NAMESPACE=kube-system

printf "Current Context: %s.\n" "$CURRENT_CONTEXT"
echo -e "\e[1;41m Are you sure you want delete sealed-secrets? [y/n] \e[0m"
read -n 1 -r
printf "\n"
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    printf "Aborted!"
    exit 1
fi

kubectl delete crd sealedsecrets.bitnami.com
kubectl delete sa sealed-secrets-controller -n $SEALED_SECRETS_NAMESPACE
kubectl delete deploy sealed-secrets-controller -n $SEALED_SECRETS_NAMESPACE
kubectl delete secret sealed-secrets-key -n $SEALED_SECRETS_NAMESPACE

printf "\n sealed-secrets deleted! \n"
