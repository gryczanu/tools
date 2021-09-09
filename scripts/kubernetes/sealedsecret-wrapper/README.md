# SealedSecret wrapper

## Quick Start Guide

1. Install needed tools
    * ksd https://github.com/mfuentesg/ksd
    * kubectl https://kubernetes.io/docs/tasks/tools/
    * yq https://github.com/mikefarah/yq

2. Make script executable and create alias for it

```sh
sudo chmod u+x secret.sh
echo "alias secret=$PWD/secret.sh" >> ~/.zshrc
```

3. Add `**/secret.env*` rule to project .gitignore file to not leak any sensitive information.

4. Start using this wrapper :)  

    REMEMBER!
    * You have to use "secret" command inside one of the overlays directory eg. "./process-manager/overlays/prod"
    * Before running commands your `kubectl context` must be set to cluster & namespace corresponding to your overlay configuration

    #### Creating secret from template

    ```sh
    secret create
    ```

    #### Updating secret

    Fetch actual secret from k8s
    ```sh
    secret get
    ```

    Make changes in secret.env.yaml. Encode secret with:
    ```sh
    secret set
    ```
    Now you can commit and push `secret.yaml` file, after merging to master secret will be synced automatically by ArgoCD

    #### Review secrets

    Checkout into branch where secret is waiting for review
    ```sh
    git checkout update/some-branch-with-new-secret
    ```

    Make review :) 
    ```sh
    secret review
    ```


