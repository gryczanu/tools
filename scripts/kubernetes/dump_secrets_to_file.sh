# dump all secrets from namespace to files
NAMESPACE=apps
SECRETS_TO_DUMP=(
example1
#example2
example3
)

## list of all secrets
#for s in `kubectl get secrets -n $NAMESPACE | awk '{if (NR!=1){print $1}}'`; do
#    echo $s
#done

for SECRET in "${SECRETS_TO_DUMP[@]}"; do
    echo "Dumping files from secret ${SECRET}:"
    for FILE_NAME in `kubectl -n ${NAMESPACE} get secret $SECRET -o json|jq -r '.data | keys[]'`
    do
      echo "- ${FILE_NAME}"
      kubectl -n ${NAMESPACE} get secret ${SECRET} -o json |jq -r '.data."'${FILE_NAME}'"' | base64 -d > ${FILE_NAME}
    done
done
