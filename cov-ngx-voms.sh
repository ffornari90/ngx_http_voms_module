#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

#geninfo --base-directory ${HOME}/openresty-1.13.6.1/build/nginx-1.13.6/objs/addon/src/ --output-filename coverage.info ${HOME}/openresty-1.13.6.1/build/nginx-1.13.6/objs/addon/src/
geninfo --output-filename /tmp/coverage.info ${HOME}/openresty-1.21.4.1/build/nginx-1.21.4/objs/addon/src/
genhtml --prefix ${HOME}/openresty-1.21.4.1/build/nginx-1.21.4/objs/addon/src/ --ignore-errors source --demangle-cpp /tmp/coverage.info \
  --legend --title "coverage ngix" --output-directory=/tmp/coverage-report

exit_status=$?
if [ ! $exit_status -eq 0 ]; then
   echo "check output"
fi
echo $exit_status

