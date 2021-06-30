#!/bin/bash

# Exit on any failure.
set -eu

TAG_NAME=""

_set_tag_string() {
  local CHART_YAML=${INPUT_CHART_DIR}/Chart.yaml
  local NAME
  local VERSION

  if [ ! -f "${CHART_YAML}" ]; then
    echo "::error::Can not find ${CHART_YAML}. Failing."
    return 1
  fi

  VERSION=$(yq eval .version "${CHART_YAML}") || return 1
  NAME=$(yq eval .name "${CHART_YAML}") || return 1

  TAG_NAME="${NAME}-${VERSION}"
}

_fix_perms() {
  # https://github.com/actions/checkout/issues/164#issuecomment-592281100
  sudo chmod -R ugo+rwX .
}

_create_tag() {
  echo "::debug::Creating tag ${TAG_NAME}..."
}

_create_release() {
  [ "${INPUT_CREATE_RELEASE}" == "true" ] || return 0

  echo "::debug::Creating release ${TAG_NAME} from ${TAG_NAME}..."

  if [ -z "${GITHUB_TOKEN}" ]; then
    echo "::error::Cannot create Github Release without setting GITHUB_TOKEN"
    return 1
  fi

  return 0
  OWNER=
  REPOSITORY=
  ACCESS_TOKEN=
  VERSION=
  curl --data '{"tag_name": "v$VERSION",
                "target_commitish": "master",
                "name": "v$VERSION",
                "body": "Release of version $VERSION",
                "draft": false,
                "prerelease": false}' \
    https://api.github.com/repos/$OWNER/$REPOSITORY/releases?access_token=$ACCESS_TOKEN
}


# Be really loud and verbose if we're running in VERBOSE mode
if [ "${INPUT_VERBOSE}" == "true" ]; then
  set -x
  echo "Environment:"
fi

_set_tag_string
_fix_perms
_create_tag
_create_release
