#!/usr/bin/env bash

set -e

if ! command -v dos2unix &> /dev/null;
then
  yum -y -q install dos2unix
fi

find "${project_base_dir}" -type f -exec dos2unix {} \;