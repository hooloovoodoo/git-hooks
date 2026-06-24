#!/usr/bin/env bash
#
# Shared helpers for HLV git hooks. Sourced (not executed) by the other hooks,
# so it must not exit on the caller's behalf except through the helpers below.

# Make tput safe in non-interactive contexts (CI, GUI git clients, dumb terminals).
if [ -z "${TERM:-}" ] || [ "${TERM}" = "dumb" ]; then
  export TERM="ansi"
fi
if command -v tput >/dev/null 2>&1 && tput sgr0 >/dev/null 2>&1; then
  bold=$(tput bold); normal=$(tput sgr0)
else
  bold=""; normal=""
fi

ORG="hooloovoodoo"

# remote_owner: print the owner segment of origin's URL, empty if no remote.
# Handles git@host:owner/repo(.git), ssh://…/owner/repo, https://host/owner/repo.
remote_owner() {
  local url
  url=$(git config --get remote.origin.url 2>/dev/null) || return 0
  [ -z "$url" ] && return 0
  if [[ $url == git@* || $url == ssh://* ]]; then
    printf '%s' "$url" | sed -E 's#^.*[:/]([^/]+)/[^/]+$#\1#'
  else
    printf '%s' "$url" | sed -E 's#^https?://[^/]+/([^/]+)/.*#\1#'
  fi
}

# remote_repo: print the repo segment of origin's URL (last path part, sans .git),
# empty if no remote. Works for git@, ssh:// and https:// forms.
remote_repo() {
  local url
  url=$(git config --get remote.origin.url 2>/dev/null) || return 0
  [ -z "$url" ] && return 0
  url=${url%.git}
  printf '%s' "${url##*/}"
}

# is_org_repo: 0 if origin owner == ORG, else 1. Repos outside the org pass through.
is_org_repo() { [ "$(remote_owner)" = "$ORG" ]; }
