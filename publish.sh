#!/bin/bash

set -euo pipefail

REGION=eu-west-1
GEMNAME=stacker

ME=`basename $0`
OS=`uname`
if [ "$OS" = "Darwin" ] ; then
    MYFULL="$0"
else
    MYFULL=`readlink -sm $0`
fi
MYDIR=`dirname $MYFULL`

fail()
{
  echo "[$ME] FAIL: $*"
  exit 1
}

cd "${MYDIR}"
[ -d ./pkg ] || fail "No ./pkg dir. Has the gem been built?"
GEM=$(ls ./pkg/"${GEMNAME}"-*.gem | sort | tail -1)
[ -n "${GEM}" ] || fail "No gem files found in ./pkg/{GEMNAME}-*.gem"

echo "[$ME] Uploading ${GEM} to s3://as24.tatsu.artefacts/gems/${GEMNAME}/"
aws --region "${REGION}" s3 cp "${GEM}" "s3://as24.tatsu.artefacts/gems/${GEMNAME}/" || fail "Could not upload gem"
