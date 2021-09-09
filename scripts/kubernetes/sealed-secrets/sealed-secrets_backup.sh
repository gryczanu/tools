#!/usr/bin/env bash

CURRENT_CONTEXT=$(kubectl config current-context)
SEALED_SECRETS_NAMESPACE=kube-system

printf "Current Context: %s.\n" "$CURRENT_CONTEXT"
read -p "Are you sure? " -n 1 -r
printf "\n"
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    printf "Aborted!"
    exit 1
fi

printf "Sealed-Secrets secret backup started...\n"

SEALED_SECRETS_DIRECTORY="./.sealed-secrets"
TLS_CERT="$SEALED_SECRETS_DIRECTORY"/tls.crt
TLS_KEY="$SEALED_SECRETS_DIRECTORY"/tls.key

if [[ -f "$TLS_CERT" || -f "$TLS_KEY" ]]; then
    read -p "You want to overwrite your keys? " -n 1 -r
    printf "\n"
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        printf "Aborted!"
        exit 1
    fi
fi

if [[ ! -d "$SEALED_SECRETS_DIRECTORY" ]]; then
  printf "Creating directory %s\n" "$SEALED_SECRETS_DIRECTORY"
  mkdir -p "$SEALED_SECRETS_DIRECTORY"
fi

SEALED_SECRETS_SECRET_NAME=$(kubectl get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key=active -n kube-system | grep sealed | awk '{print $1}')

if [[ "$SEALED_SECRETS_SECRET_NAME" == "" ]]; then
  printf "Nothing to backup... Exiting!\n"
  exit 1;
fi

kubectl get secrets "$SEALED_SECRETS_SECRET_NAME" -n "$SEALED_SECRETS_NAMESPACE" -o jsonpath='{.data.tls\.crt}' | base64 -d > "$TLS_CERT"
printf "Certificate stored to: %s\n" "$TLS_CERT"

kubectl get secrets "$SEALED_SECRETS_SECRET_NAME" -n "$SEALED_SECRETS_NAMESPACE" -o jsonpath='{.data.tls\.key}' | base64 -d > "$TLS_KEY"
printf "Key stored to: %s\n" "$TLS_KEY"

printf "\nSealed-Secrets secret backup finished...\n"
