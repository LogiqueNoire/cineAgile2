#!/usr/bin/env bash
set -e

PLUGINS_FILE="$1"

echo "Installing plugins"

jenkins-plugin-cli --plugin-file $PLUGINS_FILE

echo "Finished"