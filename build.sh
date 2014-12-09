#!/bin/bash

set -euo pipefail

if [ -n "${GEM_VERSION:-}" ] ; then
  ;
elif [ -n "${GO_PIPELINE_LABEL:-}" ] ; then
  GEM_VERSION="${GO_PIPELINE_LABEL}"
else
  echo "Setting gem version to 0000"
  GEM_VERSION="0000"
fi
export GEM_VERSION

[ -d ./pkg ] || fail "No ./pkg dir. Has the gem been built?"
GEM=$(ls ./pkg/"${GEMNAME}"-*.gem | sort | tail -1)
[ -n "${GEM}" ] || fail "No gem files found in ./pkg/{GEMNAME}-*.gem"

echo "[$ME] Uploading ${GEM} to s3://as24.tatsu.artefacts/gems/${GEMNAME}/"
aws --region "${REGION}" s3 cp "${GEM}" "s3://as24.tatsu.artefacts/gems/${GEMNAME}/" || fail "Could not upload gem"
