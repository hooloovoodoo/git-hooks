#!/bin/bash
#
# Install or update custom HLV git hooks.

REPO_NAME="hooloovoodoo/git-hooks"
REPO_URL="https://github.com/${REPO_NAME}"
API_URL="https://api.github.com/repos/${REPO_NAME}/releases/latest"
TEMPLATE_DIR="${HOME}/.git_template"
HOOKS_DIR="${TEMPLATE_DIR}/hooks"
LOCAL_HOOKS_VERSION_FILE="${HOOKS_DIR}/version"

# ensure git and jq are installed
for cmd in git jq unzip; do
  if ! command -v ${cmd} &> /dev/null; then
    echo "DEBUG :: Command ${cmd} missing."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install ${cmd}
    elif [[ -f /etc/debian_version ]]; then
      sudo apt-get install -y ${cmd}
    else
      echo "Please install it manually [!]"
      exit 1
    fi
  fi
done

# ebsure git init.templatedir is set
GIT_TEMPLATE_DIR=$(git config --global init.templatedir)
if [ -z "$GIT_TEMPLATE_DIR" ]; then
  echo "Setting global Git template directory..."
  git config --global init.templatedir "${TEMPLATE_DIR}"
  git config --global core.hooksPath "${HOOKS_DIR}"
fi

# ensure git hooks dir exists
mkdir -p "$HOOKS_DIR"

# get the latest release version
LATEST_VERSION=$(curl -s "$API_URL" | jq -r '.tag_name')

# install git hooks or update, if needed.
if [ ! -f "${LOCAL_HOOKS_VERSION_FILE}" ] || [ "${LATEST_VERSION}" != "$(cat "${LOCAL_HOOKS_VERSION_FILE}")" ]; then
  echo "Updating Git hooks..."
  curl -sL "${REPO_URL}/archive/refs/tags/${LATEST_VERSION}.zip" -o "${HOOKS_DIR}/hooks.zip"
  unzip -o "${HOOKS_DIR}/hooks.zip" -d "${HOOKS_DIR}"
  mv "${HOOKS_DIR}"/git-hooks-*/hooks/* "${HOOKS_DIR}"
  rm "${HOOKS_DIR}"/hooks.zip
  rmdir "${HOOKS_DIR}"/git-hooks-*/hooks "${HOOKS_DIR}"/git-hooks-*
  echo "${LATEST_VERSION}" > "${LOCAL_HOOKS_VERSION_FILE}"
  echo "Git hooks updated to version ${LATEST_VERSION}."
else
  echo "Hooks be good \o/"
fi

