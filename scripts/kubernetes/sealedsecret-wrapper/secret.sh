#!/bin/bash

# Needed tools
# ksd https://github.com/mfuentesg/ksd
# kubectl https://kubernetes.io/docs/tasks/tools/
# jq https://github.com/mikefarah/yq

# Global variables
ENV=$(basename $PWD)
APP_NAME=$(basename $(dirname $(dirname $PWD)))
DECODED_SECRET=secret.env.yaml
CERT_FILE=public-key-cert.pem
ENCODED_SECRET=secret.yaml

function check_if_installed() {
    for cmd in "$@"
    do
        if ! command -v $cmd &> /dev/null
        then
            echo "$cmd could not be found. Please install it on your system"
            exit
        fi
    done
}

unalias ksd 2> /dev/null # make sure zsh alias is disabled
check_if_installed yq kubectl ksd

function fetch_secret_from_k8s_and_decode_base64() {
    secret_name=$1
    kubectl get secrets $secret_name -o yaml \
    | yq eval 'del(.metadata.resourceVersion)' - \
    | yq eval 'del(.metadata.uid)' - \
    | yq eval 'del(.metadata.annotations)' - \
    | yq eval 'del(.metadata.creationTimestamp)' - \
    | yq eval 'del(.metadata.ownerReferences)' - \
    | yq eval 'del(.metadata.selfLink)' - \
    | yq eval 'del(.metadata.namespace)' - \
    | ksd
}

function change_secret_name_in_file() {
    file=$1
    secret_name=$2
    cat $file \
    | secret_name=$secret_name yq eval '.metadata.name = env(secret_name)' - \
    | secret_name=$secret_name yq eval '.spec.template.metadata.name = env(secret_name)' - > tmp-secret.yaml
    rm $file
    mv tmp-secret.yaml $file
}

function get() {
    # gets secret from k8s and decrypts base64 values
    fetch_secret_from_k8s_and_decode_base64 $ENV-$APP_NAME \
    | secret_name=$APP_NAME yq eval '.metadata.name = env(secret_name)' - > $DECODED_SECRET
}

function set() {
    # check if file exists
    if [ ! -f $DECODED_SECRET ]; then
        echo "File $DECODED_SECRET not found!. You should fetch secret with 'secret get' or create new secret with 'secret create'"
        exit 1
    fi

    # encrypt secret
    kubeseal --fetch-cert > $CERT_FILE
    kubeseal --scope namespace-wide --format=yaml --cert=$CERT_FILE < $DECODED_SECRET> $ENCODED_SECRET

    # add annotations to force pod reload
    SECRET_SHA=$(sha256sum $ENCODED_SECRET | awk '{print $1}')
    kustomize edit remove annotation -i secret-sha
    kustomize edit add annotation secret-sha:"$SECRET_SHA"

    # cleanup
    rm $CERT_FILE $DECODED_SECRET

}

function review() {
    # check if file exists
    if [ ! -f $ENCODED_SECRET ]; then
        echo "File $ENCODED_SECRET not found!. No secret to review"
        exit 1
    fi
    # replace secret name in the file
    REVIEW_SECRET_NAME=secret-review-$ENV-$APP_NAME
    change_secret_name_in_file $ENCODED_SECRET $REVIEW_SECRET_NAME

    # apply secret, fetch it and delete 
    kubectl apply -f $ENCODED_SECRET
    sleep 1
    echo "$(fetch_secret_from_k8s_and_decode_base64 $REVIEW_SECRET_NAME)" > $DECODED_SECRET
    kubectl delete -f $ENCODED_SECRET

    # rename secret back to original name
    change_secret_name_in_file $DECODED_SECRET $APP_NAME
    change_secret_name_in_file $ENCODED_SECRET $APP_NAME
    echo "You can review secrets in $DECODED_SECRET file"
}

function create() {
    cat <<EOF > secret.env.yaml
apiVersion: v1
kind: Secret
metadata:
  name: $APP_NAME
type: Opaque
stringData:
  EXAMPLE_ENV: value123
  EXAMPLE_MULTILINE_ENV: |
    line1
    line2
    line3
EOF
}

"$@"