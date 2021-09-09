#!/bin/bash

### prepare part of manifest SecretProviderClass

# apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
# kind: SecretProviderClass
# metadata:
#   name: az-kv-example-name
# spec:
#   provider: azure
#   parameters:
#     usePodIdentity: "true"
#     keyvaultName: "your-kv-name"
#     objects:  |
#       array:
#         - |
#           objectName: MY-SECRET-KEY-FROM-KV
#           objectType: secret
#         # <--- add here output
#     tenantId: "your-key-vault-directory-id"
#   secretObjects:
#     - secretName: example-secret-name-in-cluster
#       type: Opaque
#       data:
#         - objectName: MY-SECRET-KEY-FROM-KV
#           key: MY_NEW_SECRET_KEY_NAME_FROM_KV
#         # <--- add here output

ENV_LIST="./.env"
OUTPUT_FILE=kv-env-describe-for-secret.txt
APP=ias-share

if [[ ! -f "$ENV_LIST" ]]; then
    echo "$ENV_LIST not exists."
    exit -1;
fi

printf "array:\n" > $OUTPUT_FILE
for ENV_ROW in $(cat ${ENV_LIST});
do
    KV_VALUE=${ENV_ROW#*=}
    KV_ENV_NAME=${ENV_ROW%"=$KV_VALUE"}
    KV_PARSE_ENV_NAME=$(echo $KV_ENV_NAME | tr _ - | tr '[:upper:]' '[:lower:]') # parse sign _ on -
    printf "  - |\n    objectName: %s \n    objectType: secret\n" ${APP}-${KV_PARSE_ENV_NAME} >> $OUTPUT_FILE
done;

printf "data:\n" >> $OUTPUT_FILE
for ENV_ROW in $(cat ${ENV_LIST});
do
    KV_VALUE=${ENV_ROW#*=}
    KV_ENV_NAME=${ENV_ROW%"=$KV_VALUE"}
    KV_PARSE_ENV_NAME=$(echo $KV_ENV_NAME | tr _ - | tr '[:upper:]' '[:lower:]') # parse sign _ on -
    printf "  - objectName: %s\n    key: %s\n" ${APP}-${KV_PARSE_ENV_NAME} ${KV_ENV_NAME} >> $OUTPUT_FILE
done;
