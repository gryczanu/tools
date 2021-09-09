#!/bin/bash
# $1 set/get s/g
# $2 configmap name
# $3 namespace

# DEFAULT
CONFIGMAP_ENV_NAME=
NAMESPACE=
#
INPUT_ENV=.env.CM
OUTPUT_ENV=.env.CM
OUTPUT_CONFIGMAP_FILE=configmap-env.yaml
ARGUMENT=$1


if [ ! -z "$2" ]
then
  CONFIGMAP_ENV_NAME=$2
fi
if [ ! -z "$3" ]
then
  NAMESPACE=$3
fi

getConfigmap() {
  kubectl get configmap $CONFIGMAP_ENV_NAME -n $NAMESPACE -o go-template='{{range $k,$v := .data}}{{printf "%s=" $k}}{{if not $v}}{{$v}}{{else}}{{$v}}{{end}}{{"\n"}}{{end}}' > $OUTPUT_ENV
  echo -e "\e[1;42m configmap  '${CONFIGMAP_ENV_NAME}'  fetched! \e[0m"
}

setConfigmap() {
  kubectl create configmap $CONFIGMAP_ENV_NAME -n $NAMESPACE --from-env-file $INPUT_ENV --dry-run=client -o yaml > $OUTPUT_CONFIGMAP_FILE;
  echo -e "\e[1;45m configmap  '${CONFIGMAP_ENV_NAME}'  created! \e[0m"
}

if [ "${ARGUMENT}" = 'get' ] || [ "${ARGUMENT}" = 'g' ]
then
  getConfigmap
elif [ "${ARGUMENT}" = 'set' ] || [ "${ARGUMENT}" = 's' ]
then
  setConfigmap
else
  echo -e "\e[1;41m Empty argument...  \e[0m"
  printf "You can use: \n - [configmap.sh set] to set configmap \n - [configmap.sh get] to fetch configmap\n"
fi



