#!/bin/bash

# YAML registry reader
YQ="/ctx/yq"
CONFIG_DIR="/ctx/config"

read_registry() {
    local file="$1"
    local collection="$2"

    YQ_COLLECTION="$collection" "$YQ" -r '
        .groups // {}
        | to_entries[]
        | select(.value.enabled == true)
        | .value[strenv(YQ_COLLECTION)][]
        | if tag == "!!map" then
            [(.name // ""), ((.exclude // []) | join(","))] | @tsv
          else
            [., ""] | @tsv
          end
    ' "$file"
}