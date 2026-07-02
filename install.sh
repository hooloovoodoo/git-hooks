#!/bin/bash
#
# Install or update custom HLV git hooks.

REPO_NAME="hooloovoodoo/git-hooks"
REPO_URL="https://github.com/${REPO_NAME}"
API_URL="https://api.github.com/repos/${REPO_NAME}/releases/latest"
HOOKS_DIR="${HOME}/.git-hooks"
LOCAL_HOOKS_VERSION_FILE="${HOOKS_DIR}/version"

# ensure git and jq are installed
for cmd in git jq unzip; do
  if ! command -v ${cmd} &> /dev/null; then
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

# ensure git core.hooksPath points at our hooks dir
GIT_HOOKS_DIR=$(git config --global core.hooksPath)
if [ -z "$GIT_HOOKS_DIR" ]; then
  echo "Setting global core.hooksPath -> ${HOOKS_DIR}"
  git config --global core.hooksPath "${HOOKS_DIR}"
elif [ "$GIT_HOOKS_DIR" != "${HOOKS_DIR}" ]; then
  echo "[!] global core.hooksPath is '${GIT_HOOKS_DIR}', not '${HOOKS_DIR}'."
  echo "    HLV hooks will NOT run until you point it here:"
  echo "    git config --global core.hooksPath '${HOOKS_DIR}'"
fi
mkdir -p "${HOOKS_DIR}"

# get the latest release version
LATEST_VERSION=$(curl -s "$API_URL" | jq -r '.tag_name')

# install git hooks or update, if needed.
if [ ! -f "${LOCAL_HOOKS_VERSION_FILE}" ] || [ "${LATEST_VERSION}" != "$(cat "${LOCAL_HOOKS_VERSION_FILE}")" ]; then
  echo "Updating Git hooks..."
  curl -sL "${REPO_URL}/archive/refs/tags/${LATEST_VERSION}.zip" -o "${HOOKS_DIR}/hooks.zip"
  unzip -o "${HOOKS_DIR}/hooks.zip" -d "${HOOKS_DIR}"
  mv "${HOOKS_DIR}"/git-hooks-*/hooks/* "${HOOKS_DIR}"
  rm -f "${HOOKS_DIR}"/hooks.zip
  # Remove the whole extracted tree (hooks/ already moved out). rm -rf, not a
  # selective rmdir, so a new top-level entry in the zip (e.g. .github/) can't
  # leave a stray dir behind. HOOKS_DIR is fixed above, glob only matches the extract.
  rm -rf "${HOOKS_DIR}"/git-hooks-*
  chmod +x "${HOOKS_DIR}"/* 2>/dev/null || true   # ensure hooks stay executable
  echo "${LATEST_VERSION}" > "${LOCAL_HOOKS_VERSION_FILE}"
  echo "Git hooks updated to version ${LATEST_VERSION}."
else
  echo "Hooks be good \o/"
fi

# doctor: surface the most common reason a commit later gets rejected.
git_email=$(git config user.email 2>/dev/null || true)
if [ -n "$git_email" ] && [[ "$git_email" != *@hooloovoo.rs ]]; then
  echo "[!] your git user.email is '${git_email}', not *@hooloovoo.rs — commits to org repos will be rejected."
  echo "    Fix: git config --global user.email 'you@hooloovoo.rs'"
fi

