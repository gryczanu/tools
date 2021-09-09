#!/bin/bash

## decode/encode sealed-secret with .env file
# Usage: bash secret.sh [FUNCTION(s/g)] [SECRET_NAME] [NAMESPACE]
# Example: bash secret.sh g prod-my-app apps

# DEFAULT
SECRET_ENV_NAME=prod-my-app
NAMESPACE=apps
#
INPUT_ENV=.env.secret
OUTPUT_ENV=.env.secret
OUTPUT_SECRET_FILE=secret.yaml
SECRET_CERT=/path/folder/tls.crt
ARGUMENT=$1


if [ ! -z "$2" ]
then
  SECRET_ENV_NAME=$2
fi
if [ ! -z "$3" ]
then
  NAMESPACE=$3
fi


getSecret() {
  kubectl get secrets $SECRET_ENV_NAME -n $NAMESPACE -o go-template='{{range $k,$v := .data}}{{printf "%s=" $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}' > $OUTPUT_ENV
  echo -e "\e[1;42m Secret  '${SECRET_ENV_NAME}'  fetched! \e[0m"
}

sealSecret() {
  kubectl create secret generic $SECRET_ENV_NAME -n $NAMESPACE --from-env-file $INPUT_ENV --dry-run=client -o yaml | kubeseal -o yaml --cert=$SECRET_CERT > $OUTPUT_SECRET_FILE;
  echo -e "\e[1;45m Secret  '${SECRET_ENV_NAME}'  sealed! \e[0m"
}

if [ "${ARGUMENT}" = 'get' ] || [ "${ARGUMENT}" = 'g' ]
then
  getSecret
elif [ "${ARGUMENT}" = 'seal' ] || [ "${ARGUMENT}" = 's' ]
then
  sealSecret
else
  echo -e "\e[1;41m Empty argument...  \e[0m"
  printf "You can use: \n - [secret.sh seal] to encode and seal secret \n - [secret.sh get] to fetch and decode secret\n"
fi



