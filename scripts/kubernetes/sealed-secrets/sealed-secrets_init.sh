#!/usr/bin/env bash

CURRENT_CONTEXT=$(kubectl config current-context)
SEALED_SECRETS_NAMESPACE=kube-system
SEALED_SECRETS_VERSION=v0.15.0

echo "Current Context: %s.\n" "$CURRENT_CONTEXT"
echo -e "\e[1;42m Are you sure you want to install selead-secrets ${SEALED_SECRETS_VERSION}? [y/n] \e[0m"
read -n 1 -r
printf "\n"
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    printf "Aborted!"
    exit 1
fi

printf "Sealed-Secrets Controller initializing...\n"

TLS_CERT=./.sealed-secrets/tls.crt
TLS_KEY=./.sealed-secrets/tls.key

if [[ -f "$TLS_CERT" || -f "$TLS_KEY" ]]; then
  printf "TLS Key/Cert found...\n"
  kubectl create secret tls sealed-secrets-key \
  -n "$SEALED_SECRETS_NAMESPACE" --cert="$TLS_CERT" --key="$TLS_KEY"
  sleep 3
  kubectl label secrets sealed-secrets-key \
  -n "$SEALED_SECRETS_NAMESPACE" sealedsecrets.bitnami.com/sealed-secrets-key=active
fi

kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/${SEALED_SECRETS_VERSION}/controller.yaml

SEALED_SECRETS_CONTROLLER_STATUS="Pending"

while [[ "$SEALED_SECRETS_CONTROLLER_STATUS" != "Running" ]]
do
    SEALED_SECRETS_CONTROLLER_STATUS=$(kubectl get po -n "$SEALED_SECRETS_NAMESPACE" -l name=sealed-secrets-controller -o jsonpath={..status.phase})
    printf "Server Status: %s\t" "$SEALED_SECRETS_CONTROLLER_STATUS"
    sleep 5
    printf "Trying...\n"
    sleep 1
done

printf "Sealed-Secrets Successful deployed...\n"
