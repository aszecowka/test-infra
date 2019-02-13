#!/usr/bin/env bash

# This script is executed on an every PR and generates:
# - kyma-installer image
# - kyma-config-cluster.yaml
# - kyma-installer-cluster.yaml
# - is-installed.sh
# Yaml files, as well as is-installed.sh script are stored on GCS.

set -e

discoverUnsetVar=false

for var in PULL_NUMBER DOCKER_PUSH_REPOSITORY DOCKER_PUSH_DIRECTORY KYMA_ONDEMAND_ARTIFACTS_BUCKET; do
    if [ -z "${!var}" ] ; then
        echo "ERROR: $var is not set"
        discoverUnsetVar=true
    fi
done
if [ "${discoverUnsetVar}" = true ] ; then
    exit 1
fi


readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/library.sh"

function export_variables() {
   DOCKER_TAG="PR-${PULL_NUMBER}"
   readonly DOCKER_TAG
   export DOCKER_TAG
}

init
export_variables
make -C /home/prow/go/src/github.com/kyma-project/kyma/components/installer ci-pr
make -C /home/prow/go/src/github.com/kyma-project/kyma/tools/kyma-installer ci-create-ondemand-artifacts

echo "Switch to different service account"

export GOOGLE_APPLICATION_CREDENTIALS=/etc/credentials/sa-kyma-artifacts/service-account.json
authenticate

gsutil cp "${ARTIFACTS}/kyma-config-cluster.yaml" "${KYMA_ONDEMAND_ARTIFACTS_BUCKET}/${DOCKER_TAG}/kyma-config-cluster.yaml"
gsutil cp "${ARTIFACTS}/kyma-installer-cluster.yaml" "${KYMA_ONDEMAND_ARTIFACTS_BUCKET}/${DOCKER_TAG}/kyma-installer-cluster.yaml"

gsutil cp /home/prow/go/src/github.com/kyma-project/kyma/installation/scripts/is-installed.sh "${KYMA_ONDEMAND_ARTIFACTS_BUCKET}/${DOCKER_TAG}/is-installed.sh"

