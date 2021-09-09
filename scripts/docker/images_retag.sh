#!/usr/bin/env bash

function pull_image() {
    IMAGE=${1}
    printf "Pulling image: [%s]\n\n" ${IMAGE}
    docker pull ${IMAGE}
    printf "Pull image [%s] success\n\n" ${IMAGE}
}

function retag_image() {
    IMAGE=${1}
    REGISTRY=${2}
    NEW_IMAGE_NAME=${REGISTRY}/${IMAGE}
    printf "Tagging image: [%s]\n\n" ${IMAGE}
    docker tag ${IMAGE} ${NEW_IMAGE_NAME}
    printf "New tag for image [%s].\n\n" ${NEW_IMAGE_NAME}
}

function push_image() {
    IMAGE=${1}
    printf "Pushing image: [%s]\n\n" ${IMAGE}
    docker push ${IMAGE}
}

IMAGE_LIST="./images.txt"

if [[ ! -f "$IMAGE_LIST" ]]; then
    echo "$IMAGE_LIST not exists."
    exit -1;
fi

NEW_REGISTRY=${1}
for IMAGE in $(cat ${IMAGE_LIST});
do
    pull_image ${IMAGE};
    retag_image ${IMAGE} ${NEW_REGISTRY};
    push_image ${NEW_REGISTRY}/${IMAGE};
done;