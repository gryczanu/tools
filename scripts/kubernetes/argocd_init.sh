#!/usr/bin/env bash

CURRENT_CONTEXT=$(kubectl config current-context)
ARGO_CD_NAMESPACE=argocd
PASSWORD_LENGTH=16
DESTINATION_PORT=8080

printf "Current Context: %s.\n" "$CURRENT_CONTEXT"
read -p "Are you sure? " -n 1 -r
printf "\n"
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    printf "Aborted!"
    exit 1
fi

printf "ArgoCD deployment process started...\n"

OUTPUT=$(kubectl create namespace "$ARGO_CD_NAMESPACE")
if [ $? -eq 0 ]; then
    printf "%s\n" "$OUTPUT"
    unset OUTPUT
else
  exit 1
fi

OUTPUT=$(kubectl apply -n "$ARGO_CD_NAMESPACE" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml)

if [[ $? -eq 0 ]]; then
    printf "%s\n" "ArgoCD Installed."
    unset OUTPUT
else
  exit 1
fi

ARGO_CD_SERVER_STATUS=""

while [[ "$ARGO_CD_SERVER_STATUS" != "Running" ]]
do
    ARGO_CD_SERVER_STATUS=$(kubectl get po -n "$ARGO_CD_NAMESPACE" -l app.kubernetes.io/name=argocd-server -o jsonpath={..status.phase})
    printf "Server Status: %s\t" "$ARGO_CD_SERVER_STATUS"
    sleep 5
    printf "Trying...\n"
    sleep 1
done


ARGO_CD_DEFAULT_PASS=$(kubectl get po -n "$ARGO_CD_NAMESPACE" -l app.kubernetes.io/name=argocd-server -o jsonpath={..metadata.name})

printf "ArgoCD Server Status: %s\n" "$ARGO_CD_SERVER_STATUS"
printf "ArgoCD default pass: %s\n" "$ARGO_CD_DEFAULT_PASS"

read -p "Do you want to setup new password? " -n 1 -r
printf "\n"
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    printf "Aborted!"
    exit 1
fi

ARGO_CD_SERVER_SERVICE_NAME=$(kubectl get svc -n "$ARGO_CD_NAMESPACE" -l app.kubernetes.io/name=argocd-server -o jsonpath={..metadata.name})
ARGO_CD_SERVER_SERVICE_PORT=$(kubectl get svc -n "$ARGO_CD_NAMESPACE" -l app.kubernetes.io/name=argocd-server -o jsonpath={..spec."ports[1]".port})

printf "Forwarding service: %s\n" "$ARGO_CD_SERVER_SERVICE_NAME"

kubectl port-forward -n "$ARGO_CD_NAMESPACE" svc/"$ARGO_CD_SERVER_SERVICE_NAME" "$DESTINATION_PORT":"$ARGO_CD_SERVER_SERVICE_PORT" >> /dev/null 2>&1 &
PORT_FORWARD_PID="$!"
sleep 5

printf "Setup ArgoCD context\n"

argocd login localhost:8080 --insecure --username=admin --password="$ARGO_CD_DEFAULT_PASS" >> /dev/null
sleep 1

printf "Changing default pass.\n"
NEW_PASSWORD=$(openssl rand -base64 "$PASSWORD_LENGTH")

argocd account update-password --current-password "$ARGO_CD_DEFAULT_PASS" --new-password "$NEW_PASSWORD"
printf "\nPassword Changed! New password: %s\n\n" "$NEW_PASSWORD"
printf "Killing port-forward process pid: %s\n" "$PORT_FORWARD_PID"

ARGO_CD_PASS_DIR=".argocd"
ARGO_CD_ADMIN_PASS_FILE=".argocdadminpass"
ARGO_CD_DEFAULT_PASS_FILE=".argocddefaultpass"

mkdir -p "$ARGO_CD_PASS_DIR"/"$CURRENT_CONTEXT"

printf "Storing new password to file: %s/%s/%s\n" "$ARGO_CD_PASS_DIR" "$CURRENT_CONTEXT" "$ARGO_CD_ADMIN_PASS_FILE"

touch "$ARGO_CD_PASS_DIR"/"$CURRENT_CONTEXT"/"$ARGO_CD_ADMIN_PASS_FILE"
chmod 600 "$ARGO_CD_PASS_DIR"/"$CURRENT_CONTEXT"/"$ARGO_CD_ADMIN_PASS_FILE"

printf "Storing default password to file: %s/%s/%s\n" "$ARGO_CD_PASS_DIR" "$CURRENT_CONTEXT" "$ARGO_CD_DEFAULT_PASS_FILE"

touch "$ARGO_CD_PASS_DIR"/"$CURRENT_CONTEXT"/"$ARGO_CD_DEFAULT_PASS_FILE"
chmod 600 "$ARGO_CD_PASS_DIR"/"$CURRENT_CONTEXT"/"$ARGO_CD_DEFAULT_PASS_FILE"

echo "$NEW_PASSWORD" > "$ARGO_CD_PASS_DIR"/"$CURRENT_CONTEXT"/"$ARGO_CD_ADMIN_PASS_FILE"
echo "$ARGO_CD_DEFAULT_PASS" > "$ARGO_CD_PASS_DIR"/"$CURRENT_CONTEXT"/"$ARGO_CD_DEFAULT_PASS_FILE"

kill -9 "$PORT_FORWARD_PID"
