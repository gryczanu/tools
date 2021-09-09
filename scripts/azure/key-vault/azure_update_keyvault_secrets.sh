#!/bin/bash

# az login

KEYVAULT_NAME=glbl-pr-bpprgxb2b-02-key
SUBSCRIPTION_ID=2a365902-f4b6-42a7-8620-fc6ff41f649b
ENV_FILE="./.env"
APP=ias-share

if [[ ! -f "$ENV_FILE" ]]; then
    echo "$ENV_FILE not exists."
    exit -1;
fi

az account set --subscription=$SUBSCRIPTION_ID

for ENV in $(cat ${ENV_FILE});
do
    ENV_VALUE=${ENV#*=}
    ENV_NAME=${ENV%"=$ENV_VALUE"}
    PARSE_ENV_NAME=$(echo $ENV_NAME | tr _ - | tr '[:upper:]' '[:lower:]') # [OPTIONAL] parse sign _ on -
    echo "***  ${PARSE_ENV_NAME} = ${ENV_VALUE}";
    SECRET_NAME=${APP}-${PARSE_ENV_NAME}
    az keyvault secret set --name "${SECRET_NAME}" --vault-name ${KEYVAULT_NAME} --value "${ENV_VALUE}"
done;
