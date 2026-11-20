#!/bin/bash

YQ="/ctx/yq"
CONFIG_DIR="/ctx/config"
QUERY_DIR="/ctx/scripts/queries"

# Read an enabled registry group using its dedicated TOML query.
read_registry() {
  local registry="${1:-}"
  local group="${2:-}"

  [[ -n "$registry" ]] || {
    echo "Error: registry name is required" >&2
    return 1
  }

  local file="${CONFIG_DIR}/${registry}.toml"
  local query="${QUERY_DIR}/${registry}.yq"

  [[ -f "$file" ]] || {
    echo "Error: registry file not found: $file" >&2
    return 1
  }

  [[ -f "$query" ]] || {
    echo "Error: registry query not found: $query" >&2
    return 1
  }

  REGISTRY_GROUP="$group" "$YQ" \
    -p=toml \
    -o=tsv \
    --from-file "$query" \
    "$file"
}

# List enabled groups in a registry.
list_registry_groups() {
  local registry="${1:-}"

  [[ -n "$registry" ]] || {
    echo "Error: registry name is required" >&2
    return 1
  }

  local file="${CONFIG_DIR}/${registry}.toml"
  local query="${QUERY_DIR}/groups.yq"

  [[ -f "$file" ]] || {
    echo "Error: registry file not found: $file" >&2
    return 1
  }

  [[ -f "$query" ]] || {
    echo "Error: registry query not found: $query" >&2
    return 1
  }

  "$YQ" \
    -p=toml \
    -o=tsv \
    --from-file "$query" \
    "$file"
}
