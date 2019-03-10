#!/usr/bin/env bash

while true; do
  sleep 1
  arkmanager rconcmd GetChat 2>/dev/null | sed '/^Running command.*$/d' | tr -d '"' | sed '/^\s*$/d' | sed '/^Command processed.*$/d' | sed '/^Error connecting to server.*$/d'
done