#!/usr/bin/env bash

# copy all secretes from source namespace to target namespace
SOURCE_NAMESPACE=aaa-apps
TARGET_NAMESPACE=bbb-apps

printf "Copy secrets from %s to %s\n" "$SOURCE_NAMESPACE" "$TARGET_NAMESPACE."

for SECRET_NAME in `kubectl get secrets -n $SOURCE_NAMESPACE | awk '{if (NR!=1){print $1}}'`; do
  kubectl -n $SOURCE_NAMESPACE get secret $SECRET_NAME -o json | jq ".metadata.namespace=\"$TARGET_NAMESPACE\""|kubectl apply -f -
done

printf "Copy secrets complete.\n"
