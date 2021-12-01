#!/bin/bash

set -e

if [ $# -ne 2 ] 
then
  echo Usage ./rename-domain.sh OLD_DOMAIN NEW_DOMAIN
  exit 255
fi

OLD_DOMAIN=$1
NEW_DOMAIN=$2

find . -not -path "./venv/*" -type f -exec grep -l "$OLD_DOMAIN.*" {} \; -exec sed -i "s|$OLD_DOMAIN|$NEW_DOMAIN|g" {} \;
